import Foundation
import CoreGraphics

/// Processes a `RenderJob` end-to-end: drives ContinuousRenderEngine to capture
/// JPEG frames into a temp directory, packages them into a `.tendies` bundle,
/// returns the bundle's bytes.
///
/// Used by LocalHTTPServer's POST /api/render endpoint to fulfill remote
/// render requests from another iPhone.
@MainActor
enum RenderJobWorker {

    enum WorkerError: LocalizedError {
        case engineFailure(String)
        case packagingFailure(String)
        case empty

        var errorDescription: String? {
            switch self {
            case .engineFailure(let why):    return "Render engine failed: \(why)"
            case .packagingFailure(let why): return "Tendies packaging failed: \(why)"
            case .empty:                     return "Render produced no frames"
            }
        }
    }

    /// True while a job is in flight. Used to reject concurrent jobs (the
    /// engine isn't safe to invoke concurrently with another render).
    static var isBusy: Bool = false

    /// Process the job synchronously (in async terms — awaitable). Returns
    /// the .tendies bytes ready to send over HTTP.
    static func process(_ job: RenderJob) async throws -> Data {
        guard !isBusy else {
            throw WorkerError.engineFailure("server is busy with another job")
        }
        isBusy = true
        defer { isBusy = false }

        let states = job.cameraStates
        guard !states.isEmpty else { throw WorkerError.empty }

        let fm = FileManager.default
        let frameDir = fm.temporaryDirectory.appendingPathComponent(
            "remote-job-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: frameDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: frameDir) }

        let captureSize = CGSize(width: job.captureWidth, height: job.captureHeight)
        let digits = max(3, String(states.count).count)
        let jpegQuality = CGFloat(max(0.5, min(1.0, job.tendiesParams.jpegQuality)))

        // Run ContinuousRenderEngine. Frames arrive in order via the callback.
        await ContinuousRenderEngine.shared.startRender(
            states: states,
            captureSize: captureSize,
            config: job.config.snapshotConfig,
            polylineLatLons: job.polylineLatLons,
            filter: job.renderFilter,
            cancel: { false },  // No external cancel hook for v1
            onFrame: { idx, cg in
                let name = String(format: "%0*d.jpg", digits, idx)
                let url = frameDir.appendingPathComponent(name)
                try? TendiesExporter.writeCGImageAsJPEG(cg, to: url, quality: jpegQuality)
            },
            onProgress: { _, _ in }
        )

        // Validate expected frame count.
        let written = (try? fm.contentsOfDirectory(at: frameDir, includingPropertiesForKeys: nil).count) ?? 0
        guard written == states.count else {
            throw WorkerError.engineFailure("only \(written)/\(states.count) frames captured")
        }

        // Package into .tendies.
        let tendiesURL: URL
        do {
            tendiesURL = try await TendiesExporter.makeTendies(
                framesDirectory: frameDir,
                params: job.tendiesParams.tendiesParams,
                onProgress: { _, _ in }
            )
        } catch {
            throw WorkerError.packagingFailure(error.localizedDescription)
        }
        defer { try? fm.removeItem(at: tendiesURL) }

        // Read the .tendies file as Data to ship over HTTP.
        return try Data(contentsOf: tendiesURL)
    }
}
