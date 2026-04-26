import Foundation
import UIKit
import CoreLocation
import CoreGraphics

#if canImport(GoogleMaps)
import GoogleMaps
#endif

/// Snapshots a GMSMapView frame-by-frame for the .tendies / video export pipeline.
/// Apple Maps is parallel via MKMapSnapshotter; Google has no equivalent so we run
/// sequentially with a single offscreen view, waiting for `idleAt` between frames.
@MainActor
final class GoogleMapsRenderer: NSObject {

    static let shared = GoogleMapsRenderer()

    /// Tracks whether GMSServices.provideAPIKey has been called this app launch.
    /// The Google SDK refuses to recreate services with a different key — a key
    /// change requires an app restart.
    private(set) var didInitializeServices: Bool = false
    private var initializedKey: String?

    /// Initialize the GoogleMaps SDK with the user's API key. Idempotent — calling
    /// twice with the same key is a no-op. Calling with a different key returns
    /// false and prints a warning (a relaunch is required).
    @discardableResult
    func initializeServicesIfNeeded(apiKey: String) -> Bool {
        #if canImport(GoogleMaps)
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if didInitializeServices {
            if initializedKey != trimmed {
                print("[GoogleMaps] API key changed — restart required to apply.")
                return false
            }
            return true
        }
        let ok = GMSServices.provideAPIKey(trimmed)
        if ok {
            didInitializeServices = true
            initializedKey = trimmed
        }
        return ok
        #else
        return false
        #endif
    }

    /// Snapshots a single frame at the given camera state. Returns nil if Google
    /// Maps isn't available (SDK not linked, no API key, etc.).
    func snapshot(
        state: CameraState,
        widthPx: Int,
        heightPx: Int,
        styleJSON: String?,
        building3D: Bool,
        timeout: TimeInterval = 6.0
    ) async -> CGImage? {
        #if canImport(GoogleMaps)
        guard didInitializeServices else { return nil }

        // GMSMapView's "zoom" maps roughly to MKMapCamera's "distance" — convert.
        let zoom = zoomFromDistance(state.distance)

        let camera = GMSCameraPosition(
            target: CLLocationCoordinate2D(latitude: state.lat, longitude: state.lon),
            zoom: Float(zoom),
            bearing: state.heading.isFinite ? state.heading : 0,
            viewingAngle: max(0, min(67.5, state.pitch))  // Google clamps at 67.5°
        )

        let opts = GMSMapViewOptions()
        opts.camera = camera
        opts.frame = CGRect(x: 0, y: 0, width: widthPx, height: heightPx)
        let mapView = GMSMapView(options: opts)
        mapView.isMyLocationEnabled = false
        mapView.settings.compassButton = false
        mapView.settings.myLocationButton = false
        mapView.settings.zoomGestures = false
        mapView.settings.scrollGestures = false
        mapView.settings.tiltGestures = false
        mapView.settings.rotateGestures = false

        if let styleJSON = styleJSON {
            mapView.mapStyle = try? GMSMapStyle(jsonString: styleJSON)
        } else {
            mapView.mapStyle = nil
        }

        mapView.mapType = .normal
        if building3D {
            mapView.isBuildingsEnabled = true
        } else {
            mapView.isBuildingsEnabled = false
        }

        // Attach to a hidden window so tile loading actually runs (iOS suspends
        // unattached views). We position off-screen at alpha 1 — alpha 0 stops
        // tile fetches in some SDK versions.
        let window = makeOffscreenWindow(width: widthPx, height: heightPx)
        window.addSubview(mapView)

        let waiter = IdleWaiter()
        mapView.delegate = waiter

        // Wait for the map to settle (or for the timeout to fire).
        let idledNormally = await waiter.waitForIdle(timeout: timeout)
        if !idledNormally {
            print("[GoogleMaps] snapshot timed out after \(timeout)s — using current contents")
        }

        // Tiny pause for visual settle (Metal frame in flight).
        try? await Task.sleep(nanoseconds: 80_000_000)

        let cg = renderViewToCGImage(mapView, widthPx: widthPx, heightPx: heightPx)

        // Detach so resources release.
        mapView.delegate = nil
        mapView.removeFromSuperview()
        window.isHidden = true

        return cg
        #else
        _ = state
        _ = widthPx
        _ = heightPx
        _ = styleJSON
        _ = building3D
        _ = timeout
        return nil
        #endif
    }

    // MARK: - Helpers

    private func makeOffscreenWindow(width: Int, height: Int) -> UIWindow {
        let frame = CGRect(x: -CGFloat(width) - 1000, y: -CGFloat(height) - 1000,
                           width: CGFloat(width), height: CGFloat(height))
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = frame
        } else {
            window = UIWindow(frame: frame)
        }
        window.windowLevel = UIWindow.Level.normal - 1
        window.isHidden = false
        window.isUserInteractionEnabled = false
        window.alpha = 1.0  // off-screen via frame, not alpha — preserves tile fetches
        return window
    }

    private func renderViewToCGImage(_ view: UIView, widthPx: Int, heightPx: Int) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // pixel-exact, no @2x doubling
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: widthPx, height: heightPx),
            format: format
        )
        let img = renderer.image { _ in
            // drawHierarchy is the only call that captures Metal-rendered content
            // (Google Maps uses Metal under the hood). layer.render misses tiles.
            view.drawHierarchy(in: CGRect(x: 0, y: 0, width: widthPx, height: heightPx),
                               afterScreenUpdates: true)
        }
        return img.cgImage
    }

    /// Convert MKMapCamera-style "distance from camera in meters" to GMSMapView
    /// "zoom level" (logarithmic). Calibrated for typical iPhone screens — exact
    /// equivalence is impossible because the two SDKs use different camera models.
    private func zoomFromDistance(_ distanceMeters: Double) -> Double {
        // Empirical mapping anchored to iPhone wallpaper output (width ≈ 1170 px):
        //   100 m  → ~zoom 19
        //   500 m  → ~zoom 17
        //  2000 m  → ~zoom 15
        // 10000 m  → ~zoom 13
        // 50000 m  → ~zoom 11
        let d = max(50.0, distanceMeters)
        // log2 mapping with offset
        let zoom = 24.5 - log2(d)
        return max(2.0, min(21.0, zoom))
    }
}

#if canImport(GoogleMaps)
/// Tiny helper that bridges GMSMapView's idle delegate callback to async/await.
/// Resolves true on `idleAt`, or false when the timeout fires first.
@MainActor
private final class IdleWaiter: NSObject, GMSMapViewDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?

    func waitForIdle(timeout: TimeInterval) async -> Bool {
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            self.continuation = cont
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await MainActor.run {
                    guard let self = self else { return }
                    if let c = self.continuation {
                        self.continuation = nil
                        c.resume(returning: false)
                    }
                }
            }
        }
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if let c = continuation {
            continuation = nil
            c.resume(returning: true)
        }
    }
}
#endif
