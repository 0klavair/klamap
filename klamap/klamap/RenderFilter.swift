import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import UIKit

/// Post-processing color/style filters applied AFTER the map snapshot and the
/// route polyline overlay. Each filter is a chain of Core Image operations.
enum RenderFilter: String, CaseIterable, Identifiable, Sendable {
    case none
    case vintage
    case cinematic
    case mono
    case noir
    case vibrant
    case cool
    case warm
    case vhs
    case dramatic
    case sepia
    case nightDrive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:        return "None"
        case .vintage:     return "Vintage"
        case .cinematic:   return "Cinematic"
        case .mono:        return "Mono"
        case .noir:        return "Noir"
        case .vibrant:     return "Vibrant"
        case .cool:        return "Cool"
        case .warm:        return "Warm"
        case .vhs:         return "VHS"
        case .dramatic:    return "Dramatic"
        case .sepia:       return "Sepia"
        case .nightDrive:  return "Night Drive"
        }
    }

    /// Single shared CIContext — expensive to create, thread-safe to reuse.
    private static let sharedContext: CIContext = {
        // Hardware-accelerated, no software fallback.
        return CIContext(options: [.useSoftwareRenderer: false])
    }()

    /// Apply the filter to a CGImage. Returns the original on failure or for `.none`.
    nonisolated static func apply(_ filter: RenderFilter, to source: CGImage) -> CGImage {
        guard filter != .none else { return source }
        let input = CIImage(cgImage: source)
        let processed: CIImage
        switch filter {
        case .none:
            processed = input
        case .vintage:
            processed = input.applyingFilter("CIPhotoEffectInstant")
        case .cinematic:
            // Warm tint + slight saturation boost + soft vignette = "cinematic" look.
            let warm = input.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 5500, y: 0),
                "inputTargetNeutral": CIVector(x: 4400, y: -30)
            ])
            let bright = warm.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.18,
                kCIInputContrastKey: 1.10,
                kCIInputBrightnessKey: -0.02
            ])
            processed = bright.applyingFilter("CIVignette", parameters: [
                kCIInputRadiusKey: 1.6,
                kCIInputIntensityKey: 0.9
            ])
        case .mono:
            processed = input.applyingFilter("CIPhotoEffectMono")
        case .noir:
            // Higher contrast + heavier vignette than .mono — full noir aesthetic.
            let n = input.applyingFilter("CIPhotoEffectNoir")
            processed = n.applyingFilter("CIVignette", parameters: [
                kCIInputRadiusKey: 1.4,
                kCIInputIntensityKey: 1.4
            ])
        case .vibrant:
            processed = input.applyingFilter("CIVibrance", parameters: [
                kCIInputAmountKey: 1.0
            ])
        case .cool:
            processed = input.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 5500, y: 0),
                "inputTargetNeutral": CIVector(x: 7200, y: 30)
            ])
        case .warm:
            processed = input.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 5500, y: 0),
                "inputTargetNeutral": CIVector(x: 3800, y: -20)
            ])
        case .vhs:
            // Faded transfer + reduced sat + slight bloom = washed retro tape look.
            let t = input.applyingFilter("CIPhotoEffectTransfer")
            let desat = t.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.75,
                kCIInputContrastKey: 0.92
            ])
            processed = desat.applyingFilter("CIBloom", parameters: [
                kCIInputRadiusKey: 6.0,
                kCIInputIntensityKey: 0.4
            ])
        case .dramatic:
            // Chrome (cool, contrasty) + extra contrast + vignette.
            let c = input.applyingFilter("CIPhotoEffectChrome")
            let punch = c.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.25,
                kCIInputSaturationKey: 1.15
            ])
            processed = punch.applyingFilter("CIVignette", parameters: [
                kCIInputRadiusKey: 1.5,
                kCIInputIntensityKey: 1.0
            ])
        case .sepia:
            processed = input.applyingFilter("CISepiaTone", parameters: [
                kCIInputIntensityKey: 0.85
            ])
        case .nightDrive:
            // Cool-shifted, darker midtones, blue cast — night-time CarPlay feel.
            let cooled = input.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 5500, y: 0),
                "inputTargetNeutral": CIVector(x: 8000, y: 60)
            ])
            let dark = cooled.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.15,
                kCIInputContrastKey: 1.20,
                kCIInputSaturationKey: 0.85
            ])
            processed = dark.applyingFilter("CIVignette", parameters: [
                kCIInputRadiusKey: 1.8,
                kCIInputIntensityKey: 1.2
            ])
        }

        // Render back to CGImage in the source's color space.
        let extent = processed.extent.isEmpty ? input.extent : processed.extent
        return sharedContext.createCGImage(processed, from: extent) ?? source
    }
}
