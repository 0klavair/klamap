import Foundation
@preconcurrency import MapKit
import UIKit

/// Single shared MKMapView used as the rendering surface for BOTH the live
/// preview and the continuous-capture export pipeline.
///
/// Why a singleton: the bug we keep hitting in hybrid + realistic 3D mode comes
/// from the export using a DIFFERENT MKMapView (or worse, MKMapSnapshotter)
/// than the preview. Tile cache and 3D mesh state diverge, race conditions
/// emerge, frames glitch.
///
/// This registry owns ONE MKMapView for the whole app. The live preview shows
/// it. The export captures from it. Same instance, same tile cache, same Metal
/// pipeline. The export becomes architecturally guaranteed to look like the
/// preview because it IS the preview.
@MainActor
final class SharedMapViewRegistry {
    static let shared = SharedMapViewRegistry()

    /// The single MKMapView instance reused everywhere.
    let view: MKMapView

    /// Saved camera that the preview is showing — restored after an export
    /// finishes so the user lands back where they were editing.
    private var savedCamera: MKMapCamera?

    /// True while a capture session has the view "owned" — the preview UI
    /// shouldn't fight it for camera control during the export.
    private(set) var isOwnedByCapture: Bool = false

    /// Offscreen window the view lives in during a capture session. iOS needs
    /// the view to be in a window hierarchy to keep rendering / loading tiles.
    private var offscreenWindow: UIWindow?

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

    /// Attach the view to a hidden offscreen window of the given size. Required
    /// before rendering — MapKit suspends views that aren't in a window.
    func attachToOffscreenWindow(size: CGSize) {
        if let w = offscreenWindow {
            w.frame = CGRect(x: -size.width - 1000, y: -size.height - 1000,
                             width: size.width, height: size.height)
            view.frame = CGRect(origin: .zero, size: size)
            return
        }
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
        view.frame = CGRect(origin: .zero, size: size)
        view.removeFromSuperview()
        win.addSubview(view)
        offscreenWindow = win
    }

    /// Detach the view from its offscreen window after rendering done.
    func detachFromOffscreenWindow() {
        view.removeFromSuperview()
        offscreenWindow?.isHidden = true
        offscreenWindow = nil
    }

    /// Acquire exclusive control of the view for a capture session. The preview
    /// still SHOWS it (so the user can watch the trajectory animate), but it
    /// can't be interacted with.
    func acquireForCapture() {
        guard !isOwnedByCapture else { return }
        savedCamera = view.camera
        view.isZoomEnabled = false
        view.isScrollEnabled = false
        view.isPitchEnabled = false
        view.isRotateEnabled = false
        isOwnedByCapture = true
    }

    /// Release the view back to the preview — restores camera + interaction.
    func releaseFromCapture(restoreCamera: Bool = true) {
        guard isOwnedByCapture else { return }
        if restoreCamera, let cam = savedCamera {
            view.setCamera(cam, animated: false)
        }
        savedCamera = nil
        view.isZoomEnabled = true
        view.isScrollEnabled = true
        view.isPitchEnabled = true
        view.isRotateEnabled = true
        isOwnedByCapture = false
    }

    /// Apply a snapshot configuration (style, POI, hide labels, elevation) to
    /// the shared view. Called by both the preview and the renderer.
    func applyConfig(_ config: SnapshotConfig) {
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

    /// Replace the route polyline overlay with a fresh one. Pass nil to clear.
    func setPolyline(_ coords: [CLLocationCoordinate2D]?) {
        view.removeOverlays(view.overlays)
        if let coords = coords, coords.count >= 2 {
            let poly = MKPolyline(coordinates: coords, count: coords.count)
            view.addOverlay(poly, level: .aboveRoads)
        }
    }

    /// Replace the A/B annotations.
    func setAnnotations(pointA: CLLocationCoordinate2D?, pointB: CLLocationCoordinate2D?) {
        view.removeAnnotations(view.annotations)
        if let a = pointA {
            let ann = MKPointAnnotation()
            ann.coordinate = a
            ann.title = "A"
            view.addAnnotation(ann)
        }
        if let b = pointB {
            let ann = MKPointAnnotation()
            ann.coordinate = b
            ann.title = "B"
            view.addAnnotation(ann)
        }
    }
}
