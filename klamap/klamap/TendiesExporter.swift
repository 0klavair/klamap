import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import UIKit
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

enum TendiesError: LocalizedError {
    case missingTemplate
    case templateInvalid(String)
    case zipFailed(String)
    case ioFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingTemplate:
            return "Tendies template (tendies-template.zip) is missing from the app bundle."
        case .templateInvalid(let why):
            return "Tendies template is malformed: \(why)"
        case .zipFailed(let why):
            return "Tendies packaging failed: \(why)"
        case .ioFailed(let why):
            return "Tendies I/O failed: \(why)"
        }
    }
}

struct TendiesParams {
    var name: String
    var width: Int           // points (e.g. 390)
    var height: Int          // points (e.g. 844)
    var fps: Int
    var duration: Double
    var autoReverses: Bool
    var syncWithState: Bool  // map slide-to-unlock progress to animation progress
    var jpegQuality: CGFloat // 0...1
}

enum TendiesExporter {

    /// Builds a `.tendies` wallpaper bundle from a directory of frames.
    /// Frames are expected to be sorted lexicographically (e.g. `001.png`, `002.png`).
    /// Output URL is in the temp directory.
    static func makeTendies(
        framesDirectory: URL,
        params: TendiesParams,
        onProgress: @escaping (Double, String) -> Void
    ) async throws -> URL {
        #if canImport(ZIPFoundation)
        let fm = FileManager.default

        guard let templateURL = Bundle.main.url(forResource: "tendies-template", withExtension: "zip") else {
            throw TendiesError.missingTemplate
        }

        let workRoot = fm.temporaryDirectory.appendingPathComponent("tendies-work-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: workRoot, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: workRoot) }

        onProgress(0.05, "Unpacking template…")
        do {
            try fm.unzipItem(at: templateURL, to: workRoot)
        } catch {
            throw TendiesError.templateInvalid("unzip failed: \(error.localizedDescription)")
        }

        // Locate descriptor / wallpaper / .ca folders.
        let wallpaperDir = try locateWallpaperDir(in: workRoot)
        let caFolders = try locateCAFolders(in: wallpaperDir)

        // Sort frames once.
        onProgress(0.10, "Listing frames…")
        let frameURLs = try fm
            .contentsOfDirectory(at: framesDirectory, includingPropertiesForKeys: nil)
            .filter { isImageExtension($0.pathExtension) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !frameURLs.isEmpty else {
            throw TendiesError.ioFailed("frames directory is empty")
        }

        let frameCount = frameURLs.count
        let framePrefix = "frame_"
        let frameExt = ".jpg"

        // Replace Floating .ca contents.
        onProgress(0.15, "Writing animation…")
        let floatingAssets = caFolders.floating.appendingPathComponent("assets", isDirectory: true)
        try resetDirectory(at: floatingAssets)

        // Convert / copy frames as JPEG into Floating/assets/
        for (idx, src) in frameURLs.enumerated() {
            try autoreleasepool {
                let dst = floatingAssets.appendingPathComponent("\(framePrefix)\(idx)\(frameExt)")
                try writeAsJPEG(
                    sourceImageFile: src,
                    destination: dst,
                    quality: params.jpegQuality
                )
            }
            let p = 0.15 + 0.65 * (Double(idx + 1) / Double(frameCount))
            onProgress(p, "Frame \(idx + 1) / \(frameCount)")
        }

        // Floating .ca: video CAML
        let floatingCAML = TendiesTemplate.videoMainCAML(
            layerName: "Floating",
            width: params.width,
            height: params.height,
            frameCount: frameCount,
            fps: params.fps,
            duration: params.duration,
            framePrefix: framePrefix,
            frameExt: frameExt,
            autoReverses: params.autoReverses,
            syncWithState: params.syncWithState
        )
        try floatingCAML.write(
            to: caFolders.floating.appendingPathComponent("main.caml"),
            atomically: true,
            encoding: .utf8
        )

        // assetManifest with our actual frames (helps some PosterKit versions resolve assets).
        let manifestPaths = (0..<frameCount).map { "assets/\(framePrefix)\($0)\(frameExt)" }
        let manifest = TendiesTemplate.assetManifestCAML(framePaths: manifestPaths)
        try manifest.write(
            to: caFolders.floating.appendingPathComponent("assetManifest.caml"),
            atomically: true,
            encoding: .utf8
        )

        // Background and Foreground: keep transparent / empty so the video shows through.
        for ca in [caFolders.background, caFolders.foreground] {
            let layerName = ca.lastPathComponent.contains("Background") ? "Background" : "Foreground"
            let emptyCAML = TendiesTemplate.emptyMainCAML(
                layerName: layerName,
                width: params.width,
                height: params.height
            )
            try emptyCAML.write(
                to: ca.appendingPathComponent("main.caml"),
                atomically: true,
                encoding: .utf8
            )
            // Clear assets too — we don't want stale template imagery layered on top.
            let assetsDir = ca.appendingPathComponent("assets", isDirectory: true)
            try resetDirectory(at: assetsDir)
            try TendiesTemplate.assetManifestCAML(framePaths: []).write(
                to: ca.appendingPathComponent("assetManifest.caml"),
                atomically: true,
                encoding: .utf8
            )
        }

        // Re-zip
        onProgress(0.90, "Packaging .tendies…")
        let safeName = sanitizeFileName(params.name)
        let outURL = fm.temporaryDirectory
            .appendingPathComponent("\(safeName)-\(UUID().uuidString.prefix(8)).tendies")

        do {
            try fm.zipItem(at: workRoot, to: outURL, shouldKeepParent: false)
        } catch {
            throw TendiesError.zipFailed(error.localizedDescription)
        }

        onProgress(1.0, "Done")
        return outURL
        #else
        throw TendiesError.missingTemplate
        #endif
    }

    // MARK: - Filesystem helpers

    private struct CAFolders {
        let background: URL
        let floating: URL
        let foreground: URL
    }

    private static func locateWallpaperDir(in root: URL) throws -> URL {
        let fm = FileManager.default
        let descriptors = root.appendingPathComponent("descriptors", isDirectory: true)
        let descriptorContents = try fm.contentsOfDirectory(at: descriptors, includingPropertiesForKeys: nil)
        guard let descriptor = descriptorContents.first(where: { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }) else {
            throw TendiesError.templateInvalid("no descriptor directory")
        }
        let contentsDir = descriptor
            .appendingPathComponent("versions", isDirectory: true)
            .appendingPathComponent("1", isDirectory: true)
            .appendingPathComponent("contents", isDirectory: true)
        let inside = try fm.contentsOfDirectory(at: contentsDir, includingPropertiesForKeys: nil)
        guard let wp = inside.first(where: { $0.pathExtension == "wallpaper" }) else {
            throw TendiesError.templateInvalid("no .wallpaper directory")
        }
        return wp
    }

    private static func locateCAFolders(in wallpaperDir: URL) throws -> CAFolders {
        let fm = FileManager.default
        let entries = try fm.contentsOfDirectory(at: wallpaperDir, includingPropertiesForKeys: nil)
        let cas = entries.filter { $0.pathExtension == "ca" }
        guard let bg = cas.first(where: { $0.lastPathComponent.contains("Background") }),
              let fl = cas.first(where: { $0.lastPathComponent.contains("Floating") }),
              let fg = cas.first(where: { $0.lastPathComponent.contains("Foreground") }) else {
            throw TendiesError.templateInvalid("missing Background/Floating/Foreground .ca folders")
        }
        return CAFolders(background: bg, floating: fl, foreground: fg)
    }

    private static func resetDirectory(at url: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            let entries = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for e in entries { try? fm.removeItem(at: e) }
        } else {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private static func isImageExtension(_ ext: String) -> Bool {
        let e = ext.lowercased()
        return e == "png" || e == "jpg" || e == "jpeg" || e == "heic" || e == "tif" || e == "tiff"
    }

    private static func sanitizeFileName(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let cleaned = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let collapsed = String(cleaned)
        return collapsed.isEmpty ? "klamap-wallpaper" : collapsed
    }

    /// Re-encode an image file as JPEG at the requested quality. Source can be any format
    /// ImageIO understands (PNG/HEIC/JPEG/TIFF).
    private static func writeAsJPEG(
        sourceImageFile src: URL,
        destination dst: URL,
        quality: CGFloat
    ) throws {
        guard let source = CGImageSourceCreateWithURL(src as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw TendiesError.ioFailed("cannot decode \(src.lastPathComponent)")
        }
        let q = max(0.0, min(1.0, quality))
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: q
        ]
        guard let dest = CGImageDestinationCreateWithURL(dst as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw TendiesError.ioFailed("cannot create destination \(dst.lastPathComponent)")
        }
        CGImageDestinationAddImage(dest, cg, options as CFDictionary)
        if !CGImageDestinationFinalize(dest) {
            throw TendiesError.ioFailed("cannot finalize \(dst.lastPathComponent)")
        }
    }

    /// Write an in-memory CGImage as JPEG. Used by the parallel render path that hands
    /// images directly to the exporter (no PNG round-trip).
    static func writeCGImageAsJPEG(
        _ image: CGImage,
        to dst: URL,
        quality: CGFloat
    ) throws {
        let q = max(0.0, min(1.0, quality))
        guard let dest = CGImageDestinationCreateWithURL(dst as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw TendiesError.ioFailed("cannot create destination \(dst.lastPathComponent)")
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: q
        ]
        CGImageDestinationAddImage(dest, image, options as CFDictionary)
        if !CGImageDestinationFinalize(dest) {
            throw TendiesError.ioFailed("cannot finalize \(dst.lastPathComponent)")
        }
    }
}
