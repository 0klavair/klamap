import Foundation
import UIKit
@preconcurrency import MapKit
import CoreLocation
import CoreGraphics

/// Continuous-capture render engine. Replaces the discrete-snapshot pipeline
/// for hybrid + 3D mode (and eventually all modes).
///
/// Architecture: instead of `setCamera → wait → snapshot` per frame (which
/// races against MapKit's tile/mesh loader on a fresh snapshotter), we drive
/// the SHARED MKMapView's camera through the trajectory and capture each
/// frame. The view stays "live" the whole time, its tile cache stays warm,
/// the 3D mesh converges naturally — same behavior as the live preview.
///
/// User constraint C1 (no camera cuts): respected by construction. The async
/// loop advances the trajectory uniformly; camera state at frame N is exactly
/// what `pathPoint` returns for `t = N / (totalFrames - 1)`. No tapering,
/// no holds, no retries.
///
/// Design note: an earlier version used CADisplayLink to drive ticks and
/// dispatched captures via async Task. That had a race — multiple captures
/// would queue up, all reading the LATEST view state instead of the state
/// each was scheduled for. Result: many frames looked identical (the final
/// camera position). Now uses a simple `for await` loop with an explicit
/// settle delay between setCamera and capture: serial, deterministic, no race.
@MainActor
final class ContinuousRenderEngine {

    static let shared = ContinuousRenderEngine()

    /// Drive the shared MKMapView's camera through `states`, capturing each
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

        // Apply the polyline overlay (route blue line) as a native MKOverlay
        // so it follows the 3D terrain projection correctly.
        var polylineCoords: [CLLocationCoordinate2D] = []
        if let p = polylineLatLons, p.count >= 4 {
            var i = 0
            while i + 1 < p.count {
                polylineCoords.append(CLLocationCoordinate2D(latitude: p[i], longitude: p[i + 1]))
                i += 2
            }
            registry.setPolyline(polylineCoords)
        } else {
            registry.setPolyline(nil)
        }

        // Strip A/B annotations during capture (we don't want pins in the wallpaper).
        registry.setAnnotations(pointA: nil, pointB: nil)

        // Warm up: position the camera at the start state and wait for the
        // destination tiles + 3D mesh to start loading. This is the only
        // upfront wait — once the loop starts, we just sleep ~1 Vsync per frame.
        let isHybrid3D = config.style == .hybrid && config.realisticElevationWhenPitched
        await warmUp(at: states[0], mapView: mapView, isHybrid3D: isHybrid3D)

        // Per-frame settle. 33 ms = ~2 Vsync at 60 Hz, enough for MapKit to
        // redraw the new viewport. Hybrid+3D gets a touch more for mesh.
        let settleNs: UInt64 = isHybrid3D ? 50_000_000 : 33_000_000

        let total = states.count
        for idx in 0..<total {
            if cancel() { break }

            // Set camera for this frame.
            let state = states[idx]
            let cam = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
                fromDistance: max(20, state.distance),
                pitch: max(0, min(80, state.pitch)),
                heading: state.heading.isFinite ? state.heading : 0
            )
            mapView.setCamera(cam, animated: false)

            // Settle: give Metal a couple Vsync to redraw the viewport with the
            // new camera. drawHierarchy(afterScreenUpdates: true) below also
            // forces a layout pass, but the explicit sleep makes sure the new
            // camera state is visible before we ask for it.
            try? await Task.sleep(nanoseconds: settleNs)

            // Capture via drawHierarchy — only call that captures Metal-rendered
            // content. layer.render(in:) misses MapKit's Metal layer.
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

            // Apply post-process filter (CIFilter chain).
            let filtered = RenderFilter.apply(filter, to: cg)
            await onFrame(idx, filtered)
            onProgress(idx + 1, total)
        }
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
}
