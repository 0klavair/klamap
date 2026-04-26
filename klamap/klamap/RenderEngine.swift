import Foundation
@preconcurrency import MapKit
import CoreLocation
import CoreGraphics
import UIKit

/// State for a single frame: where the camera looks and from what pose.
struct CameraState: Sendable {
    let lat: Double
    let lon: Double
    let distance: Double
    let pitch: Double
    let heading: Double

    init(coord: CLLocationCoordinate2D, distance: CLLocationDistance, pitch: CGFloat, heading: CLLocationDirection) {
        self.lat = coord.latitude
        self.lon = coord.longitude
        self.distance = distance
        self.pitch = Double(pitch)
        self.heading = heading
    }
}

/// Snapshot configuration shared by every frame in a render batch. All Sendable so the
/// struct can cross actor boundaries when dispatched to background tasks.
struct SnapshotConfig: Sendable {
    enum Style: Sendable { case standard, muted, hybrid }
    let style: Style
    let showPOI: Bool
    let hideRoadLabels: Bool
    let realisticElevationWhenPitched: Bool
}

enum RenderEngine {

    /// Sweet spot for MKMapSnapshotter parallelism. Going higher tends to make MapKit
    /// stall and return blank tiles intermittently.
    nonisolated static let defaultConcurrency = 4

    /// Renders frames in parallel and calls `onFrame` on the main actor for each
    /// completed frame. Frames may complete out of order — callers receive (index, image).
    @MainActor
    static func renderFramesParallel(
        states: [CameraState],
        width: Int,
        height: Int,
        config: SnapshotConfig,
        concurrency: Int = RenderEngine.defaultConcurrency,
        cancel: @escaping @MainActor () -> Bool,
        onFrame: @escaping @MainActor (Int, CGImage) -> Void,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async {
        let total = states.count
        guard total > 0 else { return }

        // Preheat tiles around start, mid, end. Cheap small snapshots that warm
        // MapKit's tile + 3D-mesh cache so the first parallel batch doesn't all
        // hit cold caches and produce "void" frames.
        let preheatStates: [CameraState] = total == 1
            ? [states[0]]
            : [states[0], states[total / 2], states[total - 1]]
        for s in preheatStates {
            _ = await snapshotPure(
                lat: s.lat, lon: s.lon,
                distance: s.distance, pitch: s.pitch, heading: s.heading,
                width: max(64, width / 4), height: max(64, height / 4),
                style: config.style, showPOI: config.showPOI,
                hideRoadLabels: config.hideRoadLabels,
                realisticElevation: config.realisticElevationWhenPitched
            )
        }
        if cancel() { return }

        // Drive a TaskGroup with a sliding window of N concurrent snapshots.
        var nextIdx = 0
        var completed = 0
        let cap = max(1, concurrency)

        await withTaskGroup(of: (Int, CGImage?).self) { group in
            // Local enqueue helper — captures everything by value.
            @MainActor func enqueue(_ i: Int) {
                let s = states[i]
                let w = width
                let h = height
                let cfg = config
                group.addTask {
                    let cg = await RenderEngine.snapshotPure(
                        lat: s.lat, lon: s.lon,
                        distance: s.distance, pitch: s.pitch, heading: s.heading,
                        width: w, height: h,
                        style: cfg.style, showPOI: cfg.showPOI,
                        hideRoadLabels: cfg.hideRoadLabels,
                        realisticElevation: cfg.realisticElevationWhenPitched
                    )
                    if let cg = cg, RenderEngine.isLikelyBlank(cg) {
                        // Tile cache miss — let MapKit settle, nudge the camera so
                        // it re-evaluates the tile set, then try again.
                        try? await Task.sleep(nanoseconds: 30_000_000)
                        let retried = await RenderEngine.snapshotPure(
                            lat: s.lat, lon: s.lon,
                            distance: s.distance * 1.001 + 0.5, pitch: s.pitch, heading: s.heading,
                            width: w, height: h,
                            style: cfg.style, showPOI: cfg.showPOI,
                            hideRoadLabels: cfg.hideRoadLabels,
                            realisticElevation: cfg.realisticElevationWhenPitched
                        )
                        return (i, retried ?? cg)
                    }
                    return (i, cg)
                }
            }

            // Initial batch.
            let initial = min(cap, total)
            for _ in 0..<initial {
                enqueue(nextIdx)
                nextIdx += 1
            }

            // As tasks complete, deliver the frame and refill the window.
            while let (idx, cg) = await group.next() {
                completed += 1
                if let cg = cg {
                    onFrame(idx, cg)
                }
                onProgress(completed, total)

                if cancel() {
                    group.cancelAll()
                    break
                }

                if nextIdx < total {
                    enqueue(nextIdx)
                    nextIdx += 1
                }
            }
        }
    }

    /// Renders a single frame on demand. Used for image export and previews.
    @MainActor
    static func renderSingleFrame(
        state: CameraState,
        width: Int,
        height: Int,
        config: SnapshotConfig
    ) async -> CGImage? {
        return await snapshotPure(
            lat: state.lat, lon: state.lon,
            distance: state.distance, pitch: state.pitch, heading: state.heading,
            width: width, height: height,
            style: config.style, showPOI: config.showPOI,
            hideRoadLabels: config.hideRoadLabels,
            realisticElevation: config.realisticElevationWhenPitched
        )
    }

    /// Pure-input snapshot worker. Takes only Sendable primitives so it can be called
    /// from any task context without crossing MapKit types across actor boundaries.
    nonisolated static func snapshotPure(
        lat: Double,
        lon: Double,
        distance: Double,
        pitch: Double,
        heading: Double,
        width: Int,
        height: Int,
        style: SnapshotConfig.Style,
        showPOI: Bool,
        hideRoadLabels: Bool,
        realisticElevation: Bool
    ) async -> CGImage? {
        let safeDistance = guardDistance(distance, pitch: pitch)
        let safePitch = guardPitch(pitch)
        let safeHeading = heading.isFinite ? heading : 0

        let opts = MKMapSnapshotter.Options()
        opts.size = CGSize(width: width, height: height)
        opts.camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            fromDistance: safeDistance,
            pitch: CGFloat(safePitch),
            heading: safeHeading
        )

        if #available(iOS 16, *) {
            let elev: MKStandardMapConfiguration.ElevationStyle =
                (realisticElevation && safePitch > 1) ? .realistic : .flat
            switch style {
            case .standard, .muted:
                opts.preferredConfiguration = MKStandardMapConfiguration(
                    elevationStyle: elev,
                    emphasisStyle: hideRoadLabels ? .muted : (showPOI ? .default : .muted)
                )
            case .hybrid:
                opts.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: elev)
            }
            opts.pointOfInterestFilter =
                (showPOI && !hideRoadLabels) ? .includingAll : .excludingAll
        }

        let snap = MKMapSnapshotter(options: opts)
        return await withCheckedContinuation { (cont: CheckedContinuation<CGImage?, Never>) in
            snap.start(with: DispatchQueue.global(qos: .userInitiated)) { snapshot, _ in
                cont.resume(returning: snapshot?.image.cgImage)
            }
        }
    }

    // MARK: - Blank-frame heuristic

    /// Returns true when the frame looks like an all-flat / single-color image, which is
    /// what MKMapSnapshotter produces when 3D tiles haven't loaded yet (the "void" frames).
    nonisolated static func isLikelyBlank(_ cg: CGImage) -> Bool {
        let samplesW = 16
        let samplesH = 16
        let bytesPerRow = 4 * samplesW
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * samplesH)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: &pixels,
            width: samplesW,
            height: samplesH,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: samplesW, height: samplesH))

        var sum: Double = 0
        var sumSq: Double = 0
        let count = samplesW * samplesH
        for i in 0..<count {
            let r = Double(pixels[i * 4])
            let g = Double(pixels[i * 4 + 1])
            let b = Double(pixels[i * 4 + 2])
            let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            sum += lum
            sumSq += lum * lum
        }
        let mean = sum / Double(count)
        let variance = (sumSq / Double(count)) - (mean * mean)
        // Real Apple Maps frames usually score variance > 200; void frames < 30.
        return variance < 25
    }

    // MARK: - Camera math safety

    /// Greater-circle bearing between two points, with NaN/duplicate guard.
    nonisolated static func safeBearing(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D,
        fallback: CLLocationDirection
    ) -> CLLocationDirection {
        let dLat = b.latitude - a.latitude
        let dLon = b.longitude - a.longitude
        if abs(dLat) < 1e-7 && abs(dLon) < 1e-7 {
            // Identical points → atan2(0,0) collapses the camera to north which is
            // visually unrelated to the route. Fall back to the previous heading.
            return fallback
        }
        let lat1 = a.latitude * .pi / 180
        let lon1 = a.longitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let lon2 = b.longitude * .pi / 180
        let dLonRad = lon2 - lon1
        let y = sin(dLonRad) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLonRad)
        let v = atan2(y, x)
        guard v.isFinite else { return fallback }
        var brng = v * 180 / .pi
        if brng < 0 { brng += 360 }
        return brng
    }

    /// Pull the bearing-target index forward until we find a point measurably different
    /// from `start`. Avoids glitches on routes with duplicated consecutive points.
    nonisolated static func findValidBearingTarget(
        start: CLLocationCoordinate2D,
        in coords: [CLLocationCoordinate2D],
        startingAt index: Int
    ) -> CLLocationCoordinate2D? {
        guard index < coords.count else { return nil }
        for i in index..<coords.count {
            let c = coords[i]
            let dLat = c.latitude - start.latitude
            let dLon = c.longitude - start.longitude
            if abs(dLat) > 1e-7 || abs(dLon) > 1e-7 {
                return c
            }
        }
        return nil
    }

    /// Don't allow the camera to dive below the ground — that's what produces the
    /// "flying through the void" look at high pitch + tiny distance.
    nonisolated static func guardDistance(
        _ distance: Double,
        pitch: Double
    ) -> Double {
        guard distance.isFinite, distance > 0 else { return 500 }
        let pitchClamped = min(80, max(0, pitch))
        let minByPitch = 80 + pitchClamped * 6
        return max(minByPitch, distance)
    }

    nonisolated static func guardPitch(_ pitch: Double) -> Double {
        guard pitch.isFinite else { return 45 }
        return min(80, max(0, pitch))
    }
}
