import Foundation
@preconcurrency import MapKit
import UIKit

/// Singleton MKMapView used by the live preview (`RenderHostView`).
///
/// Since tick 3 of the rendering refactor, the EXPORT pipeline no longer
/// borrows this view — `ContinuousRenderEngine` creates its own offscreen
/// MKMapView for capture. Yanking the preview's view via `removeFromSuperview`
/// during export was leaving the SwiftUI host empty. Separate views still
/// share MapKit's process-wide tile cache so previewing a region warms the
/// cache for any later export of that region.
///
/// This class is now mostly a configuration helper around the preview view.
@MainActor
final class SharedMapViewRegistry {
    static let shared = SharedMapViewRegistry()

    /// The preview MKMapView. Always lives in the SwiftUI host (no manual
    /// reparenting), so the preview UI stays consistent across exports.
    let view: MKMapView

    private init() {
        let m = MKMapView(frame: .zero)
        m.isZoomEnabled = true
        m.isScrollEnabled = true
        m.isPitchEnabled = true
        m.isRotateEnabled = true
        m.showsCompass = false
        m.showsScale = false
        m.showsUserLocation = false
        m.showsBuildings = true
        view = m
    }

    // MARK: - Configuration helpers (preview-side)

    private var lastAppliedConfig: SnapshotConfig?

    func applyConfig(_ config: SnapshotConfig) {
        if let last = lastAppliedConfig,
           last.style == config.style,
           last.showPOI == config.showPOI,
           last.hideRoadLabels == config.hideRoadLabels,
           last.realisticElevationWhenPitched == config.realisticElevationWhenPitched {
            return
        }
        lastAppliedConfig = config

        if #available(iOS 17, *) {
            let elev: MKStandardMapConfiguration.ElevationStyle =
                config.realisticElevationWhenPitched ? .realistic : .flat
            switch config.style {
            case .standard, .muted:
                view.preferredConfiguration = MKStandardMapConfiguration(
                    elevationStyle: elev,
                    emphasisStyle: config.hideRoadLabels ? .muted
                        : (config.showPOI ? .default : .muted)
                )
            case .hybrid:
                view.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: elev)
            }
            view.pointOfInterestFilter =
                (config.showPOI && !config.hideRoadLabels) ? .includingAll : .excludingAll
        }
    }

    private var lastPolylineHash: Int?

    func setPolyline(_ coords: [CLLocationCoordinate2D]?) {
        let h = polylineHash(coords)
        if h == lastPolylineHash { return }
        lastPolylineHash = h
        view.removeOverlays(view.overlays)
        if let coords = coords, coords.count >= 2 {
            let poly = MKPolyline(coordinates: coords, count: coords.count)
            view.addOverlay(poly, level: .aboveRoads)
        }
    }

    private func polylineHash(_ coords: [CLLocationCoordinate2D]?) -> Int {
        guard let coords = coords, !coords.isEmpty else { return 0 }
        var h = Hasher()
        h.combine(coords.count)
        h.combine(coords.first?.latitude ?? 0)
        h.combine(coords.first?.longitude ?? 0)
        h.combine(coords.last?.latitude ?? 0)
        h.combine(coords.last?.longitude ?? 0)
        if coords.count > 2 {
            let mid = coords[coords.count / 2]
            h.combine(mid.latitude)
            h.combine(mid.longitude)
        }
        return h.finalize()
    }

    func setAnnotations(pointA: CLLocationCoordinate2D?, pointB: CLLocationCoordinate2D?) {
        let existingByLabel: [String: LabeledPointAnnotation] = Dictionary(
            uniqueKeysWithValues: view.annotations.compactMap { ($0 as? LabeledPointAnnotation).map { ($0.label, $0) } }
        )

        if let a = pointA {
            if let existing = existingByLabel["A"] {
                if existing.coordinate.latitude != a.latitude || existing.coordinate.longitude != a.longitude {
                    existing.coordinate = a
                }
            } else {
                let ann = LabeledPointAnnotation(label: "A")
                ann.coordinate = a
                view.addAnnotation(ann)
            }
        } else if let existing = existingByLabel["A"] {
            view.removeAnnotation(existing)
        }

        if let b = pointB {
            if let existing = existingByLabel["B"] {
                if existing.coordinate.latitude != b.latitude || existing.coordinate.longitude != b.longitude {
                    existing.coordinate = b
                }
            } else {
                let ann = LabeledPointAnnotation(label: "B")
                ann.coordinate = b
                view.addAnnotation(ann)
            }
        } else if let existing = existingByLabel["B"] {
            view.removeAnnotation(existing)
        }
    }
}

/// MKPointAnnotation subclass that carries an "A"/"B" label so the delegate's
/// viewFor method can render styled pins per role.
final class LabeledPointAnnotation: MKPointAnnotation {
    let label: String
    init(label: String) {
        self.label = label
        super.init()
        self.title = label
    }
}
