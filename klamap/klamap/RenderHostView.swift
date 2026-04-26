import SwiftUI
@preconcurrency import MapKit

/// SwiftUI wrapper around the shared MKMapView. Used as the rendering surface
/// in the live preview so that the preview and the export pipeline share the
/// EXACT same view instance.
///
/// This is the foundation of the continuous-capture redesign: by reading the
/// preview's camera state and writing back into it, the export becomes a
/// "screen recording" of the preview rather than a separate render.
@available(iOS 17, *)
struct RenderHostView: UIViewRepresentable {

    @Binding var camera: MKMapCamera
    var styleConfig: SnapshotConfig
    var polylineCoords: [CLLocationCoordinate2D]?
    var pointA: CLLocationCoordinate2D?
    var pointB: CLLocationCoordinate2D?

    /// Optional callback when the user moves the map manually. Used by the
    /// editor to track the crosshair / current pose.
    var onCameraChange: ((MKMapCamera) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> MKMapView {
        let v = SharedMapViewRegistry.shared.view
        v.delegate = context.coordinator
        SharedMapViewRegistry.shared.applyConfig(styleConfig)
        SharedMapViewRegistry.shared.setPolyline(polylineCoords)
        SharedMapViewRegistry.shared.setAnnotations(pointA: pointA, pointB: pointB)
        v.setCamera(camera, animated: false)
        return v
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Push UI state down. Capture mode wins — we don't fight it.
        guard !SharedMapViewRegistry.shared.isOwnedByCapture else { return }
        SharedMapViewRegistry.shared.applyConfig(styleConfig)
        SharedMapViewRegistry.shared.setPolyline(polylineCoords)
        SharedMapViewRegistry.shared.setAnnotations(pointA: pointA, pointB: pointB)
        // Only push camera if it differs meaningfully — avoids fighting user's
        // gestures.
        let current = uiView.camera
        let changed =
            abs(current.centerCoordinate.latitude - camera.centerCoordinate.latitude) > 1e-7 ||
            abs(current.centerCoordinate.longitude - camera.centerCoordinate.longitude) > 1e-7 ||
            abs(current.heading - camera.heading) > 0.1 ||
            abs(current.pitch - camera.pitch) > 0.1 ||
            abs(current.altitude - camera.altitude) > 1.0
        if changed {
            uiView.setCamera(camera, animated: false)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RenderHostView
        init(parent: RenderHostView) {
            self.parent = parent
        }

        nonisolated func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Forward changes to whoever is listening (the editor).
            Task { @MainActor [weak mapView] in
                guard let mapView = mapView else { return }
                if !SharedMapViewRegistry.shared.isOwnedByCapture {
                    self.parent.onCameraChange?(mapView.camera)
                }
            }
        }

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
}
