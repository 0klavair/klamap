import Foundation
import UIKit
@preconcurrency import MapKit
import CoreLocation
import CoreGraphics

/// Continuous-capture render engine. Drives a DEDICATED offscreen MKMapView
/// through the trajectory and captures each frame.
///
/// Architecture decision (tick 3): the engine owns its OWN MKMapView rather
/// than borrowing the preview's. The previous "share the view" approach
/// yanked the view out of SwiftUI's hierarchy via removeFromSuperview, which
/// left the preview UI empty after the first export. Separate views still
/// share MapKit's process-wide tile cache, so the second export benefits
/// from any tiles the preview has loaded.
///
/// User constraint C1 (no camera cuts): respected by construction. Sequential
/// async loop advances the trajectory uniformly.
@MainActor
final class ContinuousRenderEngine {

    static let shared = ContinuousRenderEngine()

    /// Drive a dedicated offscreen MKMapView through `states`, capturing each
    /// frame to `onFrame`. Returns when the last frame has been delivered.
    func startRender(
        states: [CameraState],
        captureSize: CGSize,
        config: SnapshotConfig,
        polylineLatLons: [Double]?,
        filter: RenderFilter,
        cancel: @escaping @MainActor () -> Bool,
        onFrame: @escaping @MainActor (Int, CGImage) async -> Void,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async {
        guard !states.isEmpty else { return }

        // Create a fresh MKMapView for this export, attached to a hidden offscreen
        // window. iOS suspends views that aren't in a window — the offscreen
        // attachment keeps tile loading + Metal rendering alive without showing
        // anything to the user.
        let (mapView, window) = makeOffscreenMapView(size: captureSize)
        defer {
            mapView.removeFromSuperview()
            window.isHidden = true
        }

        // Configure style / POI / hybrid + realistic.
        configureMapView(mapView, with: config)

        // Add route polyline as a native MKOverlay (follows 3D terrain projection).
        var polylineCoords: [CLLocationCoordinate2D] = []
        if let p = polylineLatLons, p.count >= 4 {
            var i = 0
            while i + 1 < p.count {
                polylineCoords.append(CLLocationCoordinate2D(latitude: p[i], longitude: p[i + 1]))
                i += 2
            }
            let poly = MKPolyline(coordinates: polylineCoords, count: polylineCoords.count)
            mapView.addOverlay(poly, level: .aboveRoads)
        }

        // Polyline renderer is wired through a lightweight delegate. No A/B
        // pins on the export — those are editor UI only.
        let polylineDelegate = PolylineDelegate()
        mapView.delegate = polylineDelegate

        // Warm up: position the camera at the start state and wait for tiles
        // and (if applicable) the 3D mesh to load.
        let isHybrid3D = config.style == .hybrid && config.realisticElevationWhenPitched
        await warmUp(at: states[0], mapView: mapView, isHybrid3D: isHybrid3D)

        // Per-frame settle. 33 ms = ~2 Vsync at 60 Hz.
        let settleNs: UInt64 = isHybrid3D ? 50_000_000 : 33_000_000

        let total = states.count
        for idx in 0..<total {
            if cancel() { break }

            let state = states[idx]
            let cam = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
                fromDistance: max(20, state.distance),
                pitch: max(0, min(80, state.pitch)),
                heading: state.heading.isFinite ? state.heading : 0
            )
            mapView.setCamera(cam, animated: false)

            try? await Task.sleep(nanoseconds: settleNs)

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: captureSize, format: format)
            let img = renderer.image { _ in
                mapView.drawHierarchy(in: CGRect(origin: .zero, size: captureSize),
                                      afterScreenUpdates: true)
            }
            guard let cg = img.cgImage else {
                onProgress(idx + 1, total)
                continue
            }

            let filtered = RenderFilter.apply(filter, to: cg)
            await onFrame(idx, filtered)
            onProgress(idx + 1, total)
        }
    }

    // MARK: - Private helpers

    private func makeOffscreenMapView(size: CGSize) -> (MKMapView, UIWindow) {
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
        m.isZoomEnabled = false
        m.isScrollEnabled = false
        m.isPitchEnabled = false
        m.isRotateEnabled = false
        m.showsCompass = false
        m.showsScale = false
        m.showsUserLocation = false
        m.showsBuildings = true
        win.addSubview(m)
        return (m, win)
    }

    private func configureMapView(_ mapView: MKMapView, with config: SnapshotConfig) {
        if #available(iOS 17, *) {
            let elev: MKStandardMapConfiguration.ElevationStyle =
                config.realisticElevationWhenPitched ? .realistic : .flat
            switch config.style {
            case .standard, .muted:
                mapView.preferredConfiguration = MKStandardMapConfiguration(
                    elevationStyle: elev,
                    emphasisStyle: config.hideRoadLabels ? .muted
                        : (config.showPOI ? .default : .muted)
                )
            case .hybrid:
                mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: elev)
            }
            mapView.pointOfInterestFilter =
                (config.showPOI && !config.hideRoadLabels) ? .includingAll : .excludingAll
        }
    }

    private func warmUp(at state: CameraState, mapView: MKMapView, isHybrid3D: Bool) async {
        let cam = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
            fromDistance: max(20, state.distance),
            pitch: max(0, min(80, state.pitch)),
            heading: state.heading.isFinite ? state.heading : 0
        )
        mapView.setCamera(cam, animated: false)

        let warmupSeconds: Double = isHybrid3D ? 2.5 : 0.5
        try? await Task.sleep(nanoseconds: UInt64(warmupSeconds * 1_000_000_000))
    }
}

/// Tiny delegate that just renders the route polyline. Kept private to the
/// engine so the export's view doesn't fight with the preview's delegate.
@MainActor
private final class PolylineDelegate: NSObject, MKMapViewDelegate {
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
}
