import Foundation
import CoreLocation
import CoreGraphics

/// JSON schema for a remote-render job. The client (another iPhone) serializes
/// this to send via POST /api/render to a server iPhone.
///
/// Wire format example:
/// ```json
/// {
///   "states": [
///     {"lat": 48.8, "lon": 2.3, "distance": 900, "pitch": 45, "heading": 0},
///     ...
///   ],
///   "captureWidth": 1170,
///   "captureHeight": 2532,
///   "config": {"style": "hybrid", "showPOI": false, "hideRoadLabels": true, "realisticElevationWhenPitched": true},
///   "polylineLatLons": [48.8, 2.3, 48.81, 2.32],
///   "filter": "none",
///   "tendiesParams": {
///     "name": "wallpaper",
///     "width": 390, "height": 844,
///     "fps": 30, "duration": 4.0,
///     "autoReverses": false, "syncWithState": true,
///     "jpegQuality": 0.85
///   }
/// }
/// ```
struct RenderJob: Codable, Sendable {

    struct State: Codable, Sendable {
        let lat: Double
        let lon: Double
        let distance: Double
        let pitch: Double
        let heading: Double
    }

    struct Config: Codable, Sendable {
        /// Raw value: "standard" | "muted" | "hybrid"
        let style: String
        let showPOI: Bool
        let hideRoadLabels: Bool
        let realisticElevationWhenPitched: Bool

        var snapshotConfig: SnapshotConfig {
            let s: SnapshotConfig.Style
            switch style.lowercased() {
            case "muted":  s = .muted
            case "hybrid": s = .hybrid
            default:       s = .standard
            }
            return SnapshotConfig(
                style: s,
                showPOI: showPOI,
                hideRoadLabels: hideRoadLabels,
                realisticElevationWhenPitched: realisticElevationWhenPitched
            )
        }
    }

    struct TendiesParamsJSON: Codable, Sendable {
        let name: String
        let width: Int
        let height: Int
        let fps: Int
        let duration: Double
        let autoReverses: Bool
        let syncWithState: Bool
        let jpegQuality: Double

        var tendiesParams: TendiesParams {
            TendiesParams(
                name: name,
                width: width,
                height: height,
                fps: fps,
                duration: duration,
                autoReverses: autoReverses,
                syncWithState: syncWithState,
                jpegQuality: CGFloat(max(0.5, min(1.0, jpegQuality)))
            )
        }
    }

    let states: [State]
    let captureWidth: Int
    let captureHeight: Int
    let config: Config
    let polylineLatLons: [Double]?
    /// Raw value of RenderFilter: "none", "vintage", "cinematic", etc.
    let filter: String
    let tendiesParams: TendiesParamsJSON

    /// Convert wire-format states to engine CameraStates.
    var cameraStates: [CameraState] {
        states.map { s in
            CameraState(
                coord: CLLocationCoordinate2D(latitude: s.lat, longitude: s.lon),
                distance: s.distance,
                pitch: CGFloat(s.pitch),
                heading: s.heading
            )
        }
    }

    var renderFilter: RenderFilter {
        RenderFilter(rawValue: filter) ?? .none
    }
}
