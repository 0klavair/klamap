import Foundation
import SwiftUI

/// Which map backend to use for live preview and rendering.
enum MapProviderKind: String, CaseIterable, Identifiable, Sendable {
    case appleMaps = "apple"
    case googleMaps = "google"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleMaps:  return "Apple Maps"
        case .googleMaps: return "Google Maps"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .appleMaps:  return false
        case .googleMaps: return true
        }
    }
}

/// User-controlled map style preset for Google Maps. Apple Maps uses its own
/// `LiveMapStyle` enum (already defined in ContentView.swift).
enum GoogleMapStyleKind: String, CaseIterable, Identifiable, Sendable {
    case defaultStyle = "default"
    case noLabels = "noLabels"
    case noPOI = "noPOI"
    case minimal = "minimal"
    case dark = "dark"
    case retro = "retro"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultStyle: return "Standard"
        case .noLabels:     return "No labels"
        case .noPOI:        return "No POI"
        case .minimal:      return "Minimal"
        case .dark:         return "Dark"
        case .retro:        return "Retro"
        case .custom:       return "Custom JSON"
        }
    }
}

/// Singleton settings for map provider configuration. Backed by UserDefaults
/// (preferences) and Keychain (secrets). Observable for SwiftUI.
@MainActor
final class MapProviderSettings: ObservableObject {
    static let shared = MapProviderSettings()

    private enum DefaultsKeys {
        static let provider = "klamap.mapProvider"
        static let googleStyle = "klamap.googleStyle"
        static let googleCustomJSON = "klamap.googleCustomJSON"
        static let acceptedGoogleTOS = "klamap.acceptedGoogleTOS"
        static let useGoogleBuilding3D = "klamap.useGoogleBuilding3D"
    }

    @Published var provider: MapProviderKind {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: DefaultsKeys.provider) }
    }

    @Published var googleStyle: GoogleMapStyleKind {
        didSet { UserDefaults.standard.set(googleStyle.rawValue, forKey: DefaultsKeys.googleStyle) }
    }

    @Published var googleCustomJSON: String {
        didSet { UserDefaults.standard.set(googleCustomJSON, forKey: DefaultsKeys.googleCustomJSON) }
    }

    /// User must accept the in-app warning before Google Maps activates. This is
    /// our way of making sure they understand BYOK + ToS implications before
    /// any tile request hits their billing.
    @Published var acceptedGoogleTOS: Bool {
        didSet { UserDefaults.standard.set(acceptedGoogleTOS, forKey: DefaultsKeys.acceptedGoogleTOS) }
    }

    @Published var useGoogleBuilding3D: Bool {
        didSet { UserDefaults.standard.set(useGoogleBuilding3D, forKey: DefaultsKeys.useGoogleBuilding3D) }
    }

    private init() {
        let defaults = UserDefaults.standard
        let providerRaw = defaults.string(forKey: DefaultsKeys.provider) ?? MapProviderKind.appleMaps.rawValue
        self.provider = MapProviderKind(rawValue: providerRaw) ?? .appleMaps

        let styleRaw = defaults.string(forKey: DefaultsKeys.googleStyle) ?? GoogleMapStyleKind.defaultStyle.rawValue
        self.googleStyle = GoogleMapStyleKind(rawValue: styleRaw) ?? .defaultStyle

        self.googleCustomJSON = defaults.string(forKey: DefaultsKeys.googleCustomJSON) ?? ""
        self.acceptedGoogleTOS = defaults.bool(forKey: DefaultsKeys.acceptedGoogleTOS)
        self.useGoogleBuilding3D = defaults.bool(forKey: DefaultsKeys.useGoogleBuilding3D)
    }

    // MARK: - API key access

    var googleMapsAPIKey: String? {
        KeychainHelper.readString(for: KeychainKeys.googleMapsAPIKey)
    }

    func setGoogleMapsAPIKey(_ key: String?) {
        if let key = key, !key.isEmpty {
            KeychainHelper.writeString(key, for: KeychainKeys.googleMapsAPIKey)
        } else {
            KeychainHelper.delete(KeychainKeys.googleMapsAPIKey)
        }
        // The SDK reads the API key only at first init via GMSServices.provideAPIKey
        // — we need a fresh app launch for a key change to take effect. Surface that
        // via a published flag so the settings UI can show "Restart required".
        objectWillChange.send()
    }

    var hasGoogleMapsAPIKey: Bool {
        KeychainHelper.hasValue(for: KeychainKeys.googleMapsAPIKey)
    }

    // MARK: - Effective state

    /// True when the user has selected Google AND provided a key AND accepted ToS.
    /// Renderers use this to decide whether to use the Google backend or fall back
    /// to Apple silently.
    var isGoogleMapsActive: Bool {
        provider == .googleMaps && hasGoogleMapsAPIKey && acceptedGoogleTOS
    }

    /// Returns the JSON style string to apply to GMSMapView, or nil for default.
    var effectiveStyleJSON: String? {
        switch googleStyle {
        case .defaultStyle: return nil
        case .custom:
            let trimmed = googleCustomJSON.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .noLabels:     return MapStylePresets.noLabels
        case .noPOI:        return MapStylePresets.noPOI
        case .minimal:      return MapStylePresets.minimal
        case .dark:         return MapStylePresets.dark
        case .retro:        return MapStylePresets.retro
        }
    }
}
