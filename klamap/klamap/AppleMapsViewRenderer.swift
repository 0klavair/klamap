import Foundation
import UIKit
@preconcurrency import MapKit
import CoreLocation
import CoreGraphics

/// Persistent offscreen MKMapView used for the hybrid + realistic 3D render path.
///
/// MKMapSnapshotter has a fundamental issue when called rapidly with overlapping
/// camera positions: each snapshotter independently re-fetches tiles, and the
/// 3D mesh in particular often comes back partially loaded. That manifests as
/// the trembling / glitching at the end of the route the user kept reporting.
///
/// MKMapView avoids this because it owns its tile state across camera moves —
/// when we set a new camera, it preserves what's already loaded and only fetches
/// missing tiles. The trade-off is sequential rendering only (one view at a
/// time), but for this combo (hybrid + realistic) the visual quality dwarfs the
/// speed loss.
@MainActor
final class AppleMapsViewRenderer: NSObject {

    static let shared = AppleMapsViewRenderer()

    private var window: UIWindow?
    private var mapView: MKMapView?
    private var currentSize: CGSize?
    private var currentPolylineHash: Int?
    private var renderContinuation: CheckedContinuation<Void, Never>?

    /// Lazily creates the offscreen window + map view, configures the style and
    /// adds the route polyline as a native overlay (so it gets the correct
    /// terrain projection — manual snapshot.point() compositing was 2D-only).
    func prepare(
        widthPx: Int,
        heightPx: Int,
        config: SnapshotConfig,
        polylineCoords: [CLLocationCoordinate2D]?,
        startState: CameraState
    ) async {
        let size = CGSize(width: widthPx, height: heightPx)
        ensureMapView(size: size)
        configure(config: config)
        applyPolyline(polylineCoords)
        // Warm up at the start state with a longer settle so first-frame tiles load.
        await setCameraAndWait(state: startState, timeout: 2.5)
    }

    /// Snapshot a single frame at the given camera state. Must be called after
    /// prepare(). Sequential only — each call awaits the previous one.
    func snapshot(state: CameraState, filter: RenderFilter = .none) async -> CGImage? {
        guard let mapView = mapView, let size = currentSize else { return nil }
        await setCameraAndWait(state: state, timeout: 1.5)
        guard let cg = capture(mapView, size: size) else { return nil }
        return RenderFilter.apply(filter, to: cg)
    }

    /// Tear down the offscreen view + window. Call once rendering is done.
    func release() {
        if let m = mapView {
            m.removeOverlays(m.overlays)
            m.delegate = nil
            m.removeFromSuperview()
        }
        window?.isHidden = true
        mapView = nil
        window = nil
        currentSize = nil
        currentPolylineHash = nil
        if let c = renderContinuation {
            renderContinuation = nil
            c.resume()
        }
    }

    // MARK: - Internals

    private func ensureMapView(size: CGSize) {
        if currentSize == size, mapView != nil, window != nil { return }
        // Tear down any existing setup with a different size.
        release()

        // Off-screen by frame (alpha 1 keeps tile fetches active; some MKMapView
        // versions stop tile loading when alpha == 0).
        let frame = CGRect(x: -size.width - 1000, y: -size.height - 1000,
                           width: size.width, height: size.height)
        let win: UIWindow
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            win = UIWindow(windowScene: scene)
            win.frame = frame
        } else {
            win = UIWindow(frame: frame)
        }
        win.windowLevel = UIWindow.Level.normal - 1
        win.isUserInteractionEnabled = false
        win.isHidden = false

        let m = MKMapView(frame: CGRect(origin: .zero, size: size))
        m.delegate = self
        m.isZoomEnabled = false
        m.isScrollEnabled = false
        m.isRotateEnabled = false
        m.isPitchEnabled = false
        m.showsCompass = false
        m.showsScale = false
        m.showsUserLocation = false
        m.showsBuildings = true
        win.addSubview(m)

        window = win
        mapView = m
        currentSize = size
    }

    private func configure(config: SnapshotConfig) {
        guard let m = mapView else { return }
        if #available(iOS 17, *) {
            let elev: MKStandardMapConfiguration.ElevationStyle =
                config.realisticElevationWhenPitched ? .realistic : .flat
            switch config.style {
            case .standard, .muted:
                m.preferredConfiguration = MKStandardMapConfiguration(
                    elevationStyle: elev,
                    emphasisStyle: config.hideRoadLabels ? .muted : (config.showPOI ? .default : .muted)
                )
            case .hybrid:
                m.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: elev)
            }
            m.pointOfInterestFilter =
                (config.showPOI && !config.hideRoadLabels) ? .includingAll : .excludingAll
        }
    }

    private func applyPolyline(_ coords: [CLLocationCoordinate2D]?) {
        guard let m = mapView else { return }
        let h = polylineHash(coords)
        if h == currentPolylineHash { return }
        m.removeOverlays(m.overlays)
        if let coords = coords, coords.count >= 2 {
            let poly = MKPolyline(coordinates: coords, count: coords.count)
            m.addOverlay(poly, level: .aboveRoads)
        }
        currentPolylineHash = h
    }

    private func polylineHash(_ coords: [CLLocationCoordinate2D]?) -> Int {
        guard let coords = coords else { return 0 }
        var h = Hasher()
        h.combine(coords.count)
        for c in coords {
            h.combine(c.latitude)
            h.combine(c.longitude)
        }
        return h.finalize()
    }

    private func setCameraAndWait(state: CameraState, timeout: TimeInterval) async {
        guard let m = mapView else { return }
        let cam = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
            fromDistance: max(20, state.distance),
            pitch: max(0, min(80, state.pitch)),  // MKMapCamera tops at 80
            heading: state.heading.isFinite ? state.heading : 0
        )
        // Trigger camera change.
        m.setCamera(cam, animated: false)

        // Wait for "fully rendered" delegate callback OR timeout.
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            renderContinuation = cont
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await MainActor.run {
                    if let c = self?.renderContinuation {
                        self?.renderContinuation = nil
                        c.resume()
                    }
                }
            }
        }
    }

    private func capture(_ view: UIView, size: CGSize) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { _ in
            // drawHierarchy is the only call that captures Metal-rendered content
            // (MapKit uses Metal for the 3D mesh). layer.render misses tiles.
            view.drawHierarchy(in: CGRect(origin: .zero, size: size),
                               afterScreenUpdates: true)
        }
        return img.cgImage
    }
}

extension AppleMapsViewRenderer: MKMapViewDelegate {

    nonisolated func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            r.lineWidth = 5
            r.lineJoin = .round
            r.lineCap = .round
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    nonisolated func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        guard fullyRendered else { return }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if let c = self.renderContinuation {
                self.renderContinuation = nil
                c.resume()
            }
        }
    }
}
