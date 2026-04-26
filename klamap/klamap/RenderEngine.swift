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
    /// `onFrame` is async so callers can await AVAssetWriter back-pressure or disk I/O
    /// without losing the parallelism upstream.
    /// `polylineLatLons` (flat [lat, lon, lat, lon, ...]) is composited as a blue
    /// stroked path on top of every frame — same overlay as the live preview map.
    @MainActor
    static func renderFramesParallel(
        states: [CameraState],
        width: Int,
        height: Int,
        config: SnapshotConfig,
        polylineLatLons: [Double]? = nil,
        filter: RenderFilter = .none,
        previewModeRender: Bool = true,
        concurrency: Int = RenderEngine.defaultConcurrency,
        cancel: @escaping @MainActor () -> Bool,
        onFrame: @escaping @MainActor (Int, CGImage) async -> Void,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async {
        let total = states.count
        guard total > 0 else { return }

        // Coarse preheat: 5 evenly-spaced low-res snapshots warm Apple's tile cache
        // for the rough route region. Cheap (~1-2 s total).
        let coarseIndices: [Int] = total == 1 ? [0]
            : (0..<5).map { min(total - 1, Int(round(Double($0) * Double(total - 1) / 4.0))) }
        for i in coarseIndices {
            let s = states[i]
            _ = await snapshotPure(
                lat: s.lat, lon: s.lon,
                distance: s.distance, pitch: s.pitch, heading: s.heading,
                width: max(128, width / 2), height: max(128, height / 2),
                style: config.style, showPOI: config.showPOI,
                hideRoadLabels: config.hideRoadLabels,
                realisticElevation: config.realisticElevationWhenPitched
            )
        }

        // Targeted preheat for the END of the route at FULL resolution. This is
        // where we observed the worst hybrid + realistic 3D glitches: destination
        // tiles were cold, MKMapSnapshotter returned before the 3D mesh loaded,
        // and frames showed flat satellite without the buildings. By snapping the
        // last few frames sequentially before the parallel batch, the destination
        // mesh tiles are loaded and cached for the real run.
        let needsEndWarmup = (config.style == .hybrid && config.realisticElevationWhenPitched)
        if needsEndWarmup && total > 10 {
            let endCount = max(3, min(8, total / 20))
            let warmStart = total - endCount
            for i in warmStart..<total {
                let s = states[i]
                _ = await snapshotPure(
                    lat: s.lat, lon: s.lon,
                    distance: s.distance, pitch: s.pitch, heading: s.heading,
                    width: width, height: height,
                    style: config.style, showPOI: config.showPOI,
                    hideRoadLabels: config.hideRoadLabels,
                    realisticElevation: config.realisticElevationWhenPitched
                )
            }
        }

        if cancel() { return }

        // Hybrid + realistic 3D: route to the persistent MKMapView renderer.
        // MKMapSnapshotter has unfixable issues with rapid sequential calls in
        // hybrid mode (trembling, partial mesh loads). MKMapView preserves its
        // tile state across camera moves so it doesn't suffer from the race.
        let isFragileHybrid = (config.style == .hybrid && config.realisticElevationWhenPitched)
        if isFragileHybrid {
            await renderFramesViaPersistentMapView(
                states: states,
                width: width,
                height: height,
                config: config,
                polylineLatLons: polylineLatLons,
                filter: filter,
                previewLike: previewModeRender,
                cancel: cancel,
                onFrame: onFrame,
                onProgress: onProgress
            )
            return
        }

        let cap = max(1, concurrency)
        let postSnapSettleNs: UInt64 = 0
        var nextIdx = 0
        var completed = 0
        let polyline = polylineLatLons  // capture for closures

        await withTaskGroup(of: (Int, CGImage?).self) { group in
            @MainActor func enqueue(_ i: Int) {
                let s = states[i]
                let w = width
                let h = height
                let cfg = config
                let poly = polyline
                let settleNs = postSnapSettleNs
                let filt = filter
                group.addTask {
                    let cg = await RenderEngine.snapshotPure(
                        lat: s.lat, lon: s.lon,
                        distance: s.distance, pitch: s.pitch, heading: s.heading,
                        width: w, height: h,
                        style: cfg.style, showPOI: cfg.showPOI,
                        hideRoadLabels: cfg.hideRoadLabels,
                        realisticElevation: cfg.realisticElevationWhenPitched,
                        polylineLatLons: poly,
                        filter: filt
                    )
                    if settleNs > 0 {
                        try? await Task.sleep(nanoseconds: settleNs)
                    }
                    if let cg = cg, RenderEngine.isLikelyBlank(cg) {
                        try? await Task.sleep(nanoseconds: 30_000_000)
                        let retried = await RenderEngine.snapshotPure(
                            lat: s.lat, lon: s.lon,
                            distance: s.distance * 1.001 + 0.5, pitch: s.pitch, heading: s.heading,
                            width: w, height: h,
                            style: cfg.style, showPOI: cfg.showPOI,
                            hideRoadLabels: cfg.hideRoadLabels,
                            realisticElevation: cfg.realisticElevationWhenPitched,
                            polylineLatLons: poly,
                            filter: filt
                        )
                        return (i, retried ?? cg)
                    }
                    return (i, cg)
                }
            }

            let initial = min(cap, total)
            for _ in 0..<initial {
                enqueue(nextIdx)
                nextIdx += 1
            }

            while let (idx, cg) = await group.next() {
                completed += 1
                if let cg = cg {
                    await onFrame(idx, cg)
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

    /// Persistent-MKMapView path for hybrid + realistic 3D. Sequential by nature
    /// (one map view at a time) but each frame benefits from cached tiles, so
    /// total time is comparable to the parallel snapshotter path while being
    /// trembling-free. The route polyline is added as a native MKOverlay so it
    /// projects correctly onto the 3D terrain.
    @MainActor
    private static func renderFramesViaPersistentMapView(
        states: [CameraState],
        width: Int,
        height: Int,
        config: SnapshotConfig,
        polylineLatLons: [Double]?,
        filter: RenderFilter,
        previewLike: Bool,
        cancel: @escaping @MainActor () -> Bool,
        onFrame: @escaping @MainActor (Int, CGImage) async -> Void,
        onProgress: @escaping @MainActor (Int, Int) -> Void
    ) async {
        let renderer = AppleMapsViewRenderer.shared

        // Convert flat lat/lon list back to coordinate pairs.
        var coords: [CLLocationCoordinate2D] = []
        if let p = polylineLatLons, p.count >= 4 {
            var i = 0
            while i + 1 < p.count {
                coords.append(CLLocationCoordinate2D(latitude: p[i], longitude: p[i + 1]))
                i += 2
            }
        }

        await renderer.prepare(
            widthPx: width,
            heightPx: height,
            config: config,
            polylineCoords: coords.isEmpty ? nil : coords,
            startState: states[0]
        )
        defer {
            // Tear down on the next main actor hop so the closure outlives the
            // current frame's drawHierarchy.
            Task { @MainActor in renderer.release() }
        }

        // Same-state short-circuit. The user's CSV log proved that frames with
        // IDENTICAL camera state were producing DIFFERENT renders because
        // MapKit kept loading tiles in the background between snapshots.
        // For consecutive identical states (typically the end-hold frames at
        // profT=1.0), we reuse the previous frame's CGImage instead of
        // re-rendering — guarantees pixel-identical hold portion.
        let total = states.count
        var lastState: CameraState?
        var lastImage: CGImage?
        for (idx, state) in states.enumerated() {
            if cancel() { break }
            if let last = lastState, statesEqual(state, last), let img = lastImage {
                await onFrame(idx, img)
            } else {
                if let cg = await renderer.snapshot(state: state, filter: filter, previewLike: previewLike) {
                    await onFrame(idx, cg)
                    lastImage = cg
                    lastState = state
                }
            }
            onProgress(idx + 1, total)
        }
    }

    /// Coordinate-precision equality used to detect "this is the same camera
    /// state, just rendered again" — drives the hold-frame short-circuit.
    nonisolated private static func statesEqual(_ a: CameraState, _ b: CameraState) -> Bool {
        let eps = 1e-9
        return abs(a.lat - b.lat) < eps
            && abs(a.lon - b.lon) < eps
            && abs(a.distance - b.distance) < 0.01
            && abs(a.pitch - b.pitch) < 0.001
            && abs(a.heading - b.heading) < 0.001
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
    /// If `polylineLatLons` is provided (flat array of [lat0, lon0, lat1, lon1, ...]),
    /// the points are projected to image coordinates and a stroked path is composited
    /// on top of the snapshot — used to draw the CarPlay-style blue route overlay.
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
        realisticElevation: Bool,
        polylineLatLons: [Double]? = nil,
        polylineColorRGBA: (Double, Double, Double, Double) = (0, 122.0/255.0, 1, 1),
        polylineWidth: Double = 5,
        filter: RenderFilter = .none
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

        if #available(iOS 17, *) {
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
                guard let snapshot = snapshot else {
                    cont.resume(returning: nil)
                    return
                }

                // Helper to apply optional CIFilter post-processing before return.
                func finalize(_ cg: CGImage?) -> CGImage? {
                    guard let cg = cg else { return nil }
                    return RenderFilter.apply(filter, to: cg)
                }

                // No polyline → just hand back the (optionally filtered) raw snapshot.
                guard let coords = polylineLatLons, coords.count >= 4 else {
                    cont.resume(returning: finalize(snapshot.image.cgImage))
                    return
                }

                // Composite the polyline onto the snapshot. snapshot.point(for:)
                // is the only way to project geo coords onto image space and lives
                // on the snapshot object, so we have to do this here.
                let baseImage = snapshot.image
                UIGraphicsBeginImageContextWithOptions(baseImage.size, true, baseImage.scale)
                baseImage.draw(at: .zero)
                if let ctx = UIGraphicsGetCurrentContext() {
                    let (r, g, b, a) = polylineColorRGBA
                    ctx.setStrokeColor(UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a)).cgColor)
                    ctx.setLineWidth(CGFloat(polylineWidth))
                    ctx.setLineJoin(.round)
                    ctx.setLineCap(.round)
                    let bounds = CGRect(origin: .zero, size: baseImage.size)
                    var didMove = false
                    var i = 0
                    while i + 1 < coords.count {
                        let c = CLLocationCoordinate2D(latitude: coords[i], longitude: coords[i + 1])
                        let pt = snapshot.point(for: c)
                        if bounds.contains(pt) {
                            if !didMove {
                                ctx.move(to: pt)
                                didMove = true
                            } else {
                                ctx.addLine(to: pt)
                            }
                        }
                        i += 2
                    }
                    ctx.strokePath()
                }
                let composited = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                cont.resume(returning: finalize(composited?.cgImage ?? baseImage.cgImage))
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

    /// Sanitize distance against NaN/zero/negative. We deliberately do NOT impose a
    /// pitch-based minimum here: users want to be able to dive close to the ground
    /// for cinematic shots, and MapKit itself caps things at the terrain surface.
    nonisolated static func guardDistance(
        _ distance: Double,
        pitch: Double
    ) -> Double {
        guard distance.isFinite, distance > 0 else { return 500 }
        return max(20, distance)  // 20 m floor — below that MapKit clips into terrain
    }

    nonisolated static func guardPitch(_ pitch: Double) -> Double {
        guard pitch.isFinite else { return 45 }
        // MKMapCamera tops out around 85° in practice; above that the horizon flips.
        return min(85, max(0, pitch))
    }
}
