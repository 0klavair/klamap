import SwiftUI

@main
struct KlamapApp: App {

    init() {
        // Initialize Google Maps SDK at app launch if the user has stored a key
        // and accepted the BYOK warning. Apple Maps users see no behavior change.
        let settings = MapProviderSettings.shared
        if settings.acceptedGoogleTOS, let key = settings.googleMapsAPIKey, !key.isEmpty {
            _ = GoogleMapsRenderer.shared.initializeServicesIfNeeded(apiKey: key)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
