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

        // Camera change tracking. regionDidChangeAnimated alone misses pure-camera
        // changes (set with animated:false). mapViewDidChangeVisibleRegion is the
        // continuous, every-tick callback we actually want.
        nonisolated func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            Task { @MainActor [weak mapView] in
                guard let mapView = mapView else { return }
                if !SharedMapViewRegistry.shared.isOwnedByCapture {
                    self.parent.onCameraChange?(mapView.camera)
                }
            }
        }

        // A/B pins styled to match the SwiftUI version (ultraThinMaterial circle
        // with the letter on top). Returning a custom MKAnnotationView here is
        // what the user expected from the SwiftUI Annotation { pin("A") } code.
        nonisolated func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let labeled = annotation as? LabeledPointAnnotation else { return nil }
            let identifier = "labeled-pin"
            let view: MKAnnotationView
            if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                view = dequeued
                view.annotation = annotation
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
            view.canShowCallout = false

            // Build a simple pin: circle background + letter label.
            view.subviews.forEach { $0.removeFromSuperview() }
            let bg = UIView(frame: view.bounds)
            bg.backgroundColor = UIColor.white.withAlphaComponent(0.85)
            bg.layer.cornerRadius = 17
            bg.layer.borderWidth = 1.5
            bg.layer.borderColor = UIColor.black.withAlphaComponent(0.25).cgColor
            view.addSubview(bg)
            let label = UILabel(frame: view.bounds)
            label.text = labeled.label
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            label.textColor = .black
            view.addSubview(label)
            view.centerOffset = CGPoint(x: 0, y: -17)
            return view
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
