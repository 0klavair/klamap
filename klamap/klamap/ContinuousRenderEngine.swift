import Foundation
import UIKit
@preconcurrency import MapKit
import CoreLocation
import CoreGraphics
import QuartzCore

/// Continuous-capture render engine. Replaces the discrete-snapshot pipeline
/// for hybrid + 3D mode (and eventually all modes).
///
/// Architecture: instead of `setCamera → wait → snapshot` per frame (which
/// races against MapKit's tile/mesh loader), we use a CADisplayLink to drive
/// the SHARED MKMapView's camera continuously, then capture each Vsync. The
/// view stays "live" the whole time, its tile cache stays warm, the 3D mesh
/// converges naturally — same behavior as the live preview.
///
/// User constraint C1 (no camera cuts): respected by construction. The DisplayLink
/// advances time uniformly; camera state at frame N is exactly what `pathPoint`
/// returns for `t = N / (totalFrames - 1)`. No tapering, no holds, no retries.
@MainActor
final class ContinuousRenderEngine {

    static let shared = ContinuousRenderEngine()

    private var displayLink: CADisplayLink?
    private var states: [CameraState] = []
    private var currentIndex: Int = 0
    private var totalFrames: Int = 0
    private var captureSize: CGSize = .zero
    private var filter: RenderFilter = .none
    private var onFrame: (@MainActor (Int, CGImage) async -> Void)?
    private var onProgress: (@MainActor (Int, Int) -> Void)?
    private var onComplete: (@MainActor () -> Void)?
    private var cancelCheck: (@MainActor () -> Bool)?
    private var completionContinuation: CheckedContinuation<Void, Never>?

    /// Drive the shared MKMapView's camera through `states` at the device's
    /// preferred refresh rate, capturing each frame to `onFrame`. Returns when
    /// the last frame has been delivered.
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

        let registry = SharedMapViewRegistry.shared
        let mapView = registry.view

        // Acquire the shared view exclusively + attach to an offscreen window.
        registry.acquireForCapture()
        registry.attachToOffscreenWindow(size: captureSize)
        defer {
            registry.detachFromOffscreenWindow()
            registry.releaseFromCapture()
        }

        // Apply the export config (style / POI / hybrid + realistic).
        registry.applyConfig(config)

        // Apply the polyline overlay (route blue line).
        var polylineCoords: [CLLocationCoordinate2D]? = nil
        if let p = polylineLatLons, p.count >= 4 {
            var coords: [CLLocationCoordinate2D] = []
            var i = 0
            while i + 1 < p.count {
                coords.append(CLLocationCoordinate2D(latitude: p[i], longitude: p[i + 1]))
                i += 2
            }
            polylineCoords = coords
            registry.setPolyline(coords)
        } else {
            registry.setPolyline(nil)
        }

        // Warm up: position the camera at the start state and wait long enough
        // for the destination tiles + 3D mesh to begin loading. This is the
        // ONLY place we wait — once started, the DisplayLink never blocks.
        await warmUp(at: states[0], mapView: mapView, isHybrid3D: config.style == .hybrid && config.realisticElevationWhenPitched)

        // Save callbacks for the DisplayLink tick.
        self.states = states
        self.totalFrames = states.count
        self.currentIndex = 0
        self.captureSize = captureSize
        self.filter = filter
        self.onFrame = onFrame
        self.onProgress = onProgress
        self.cancelCheck = cancel

        // Run until completion.
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.completionContinuation = cont
            self.startDisplayLink()
        }

        // Cleanup
        self.states = []
        self.onFrame = nil
        self.onProgress = nil
        self.cancelCheck = nil
        // Polyline stays on the view for the preview; user can clear it via UI.

        _ = polylineCoords  // silence unused warning when polyline is nil
    }

    // MARK: - Warm-up

    private func warmUp(at state: CameraState, mapView: MKMapView, isHybrid3D: Bool) async {
        let cam = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
            fromDistance: max(20, state.distance),
            pitch: max(0, min(80, state.pitch)),
            heading: state.heading.isFinite ? state.heading : 0
        )
        mapView.setCamera(cam, animated: false)

        // Hybrid + realistic 3D needs more time for mesh tiles. Other modes
        // are quicker.
        let warmupSeconds: Double = isHybrid3D ? 2.5 : 0.5
        try? await Task.sleep(nanoseconds: UInt64(warmupSeconds * 1_000_000_000))
    }

    // MARK: - DisplayLink loop

    private func startDisplayLink() {
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        if #available(iOS 15.0, *) {
            // Run as fast as the device can. Pro displays go 120 Hz, others 60.
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        // Cancel? Stop everything cleanly.
        if cancelCheck?() == true {
            finishRender()
            return
        }

        // All frames delivered?
        if currentIndex >= totalFrames {
            finishRender()
            return
        }

        let idx = currentIndex
        let state = states[idx]
        currentIndex += 1

        // Apply the camera for this frame.
        let mapView = SharedMapViewRegistry.shared.view
        let cam = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
            fromDistance: max(20, state.distance),
            pitch: max(0, min(80, state.pitch)),
            heading: state.heading.isFinite ? state.heading : 0
        )
        mapView.setCamera(cam, animated: false)

        // Capture happens on the NEXT main-actor turn so MapKit gets one Vsync
        // to redraw the new viewport before we drawHierarchy.
        let size = captureSize
        let filter = filter
        let onFrame = onFrame
        let onProgress = onProgress
        let total = totalFrames
        Task { @MainActor in
            // Brief Vsync wait — gives Metal one frame to compose the new camera.
            try? await Task.sleep(nanoseconds: 16_000_000)  // ~1 Vsync at 60 Hz

            // Capture via drawHierarchy (only call that captures Metal content).
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let img = renderer.image { _ in
                mapView.drawHierarchy(in: CGRect(origin: .zero, size: size),
                                      afterScreenUpdates: true)
            }
            guard let cg = img.cgImage else {
                onProgress?(idx + 1, total)
                return
            }
            // Apply post-process filter (CIFilter chain).
            let filtered = RenderFilter.apply(filter, to: cg)
            await onFrame?(idx, filtered)
            onProgress?(idx + 1, total)
        }
    }

    private func finishRender() {
        stopDisplayLink()
        if let cont = completionContinuation {
            completionContinuation = nil
            cont.resume()
        }
    }
}
