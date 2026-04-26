import SwiftUI

/// Settings sheet to choose between Apple Maps and Google Maps, manage the user's
/// Google API key, accept the BYOK warning, and pick a Google style preset.
struct MapProviderSettingsView: View {
    @ObservedObject private var settings = MapProviderSettings.shared
    let L = Localization.current

    @State private var apiKeyDraft: String = ""
    @State private var showWarning: Bool = false
    @State private var showSavedToast: Bool = false

    var body: some View {
        Form {
            providerSection
            if settings.provider == .googleMaps {
                apiKeySection
                styleSection
                threeDSection
                helpSection
            }
        }
        .navigationTitle(L.mapProviderTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L.googleWarningTitle, isPresented: $showWarning) {
            Button(L.cancel, role: .cancel) {
                settings.provider = .appleMaps
            }
            Button(L.iAccept) {
                settings.acceptedGoogleTOS = true
            }
        } message: {
            Text(L.googleWarningMessage)
        }
        .onAppear {
            apiKeyDraft = settings.googleMapsAPIKey ?? ""
            if settings.provider == .googleMaps && !settings.acceptedGoogleTOS {
                showWarning = true
            }
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                Text(L.savedRestartRequired)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var providerSection: some View {
        Section {
            Picker(L.mapProvider, selection: $settings.provider) {
                ForEach(MapProviderKind.allCases) { p in
                    Text(p.displayName).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.provider) { newValue in
                // iOS 16-compatible single-arg form. iOS 17+ has (oldValue, newValue);
                // sticking with the deprecated-on-17 single-arg form keeps both.
                if newValue == .googleMaps && !settings.acceptedGoogleTOS {
                    showWarning = true
                }
            }
        } footer: {
            Text(settings.provider == .appleMaps ? L.appleMapsFooter : L.googleMapsFooter)
        }
    }

    private var apiKeySection: some View {
        Section {
            SecureField(L.googleAPIKeyPlaceholder, text: $apiKeyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.system(.body, design: .monospaced))

            HStack {
                Button {
                    if let s = UIPasteboard.general.string {
                        apiKeyDraft = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Label(L.paste, systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    settings.setGoogleMapsAPIKey(apiKeyDraft)
                    withAnimation { showSavedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showSavedToast = false }
                    }
                } label: {
                    Label(L.save, systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if settings.hasGoogleMapsAPIKey {
                Button(role: .destructive) {
                    settings.setGoogleMapsAPIKey(nil)
                    apiKeyDraft = ""
                } label: {
                    Label(L.deleteKey, systemImage: "trash")
                }
            }
        } header: {
            Text(L.googleAPIKey)
        } footer: {
            Text(L.googleAPIKeyFooter)
        }
    }

    private var styleSection: some View {
        Section {
            Picker(L.mapStyle, selection: $settings.googleStyle) {
                ForEach(GoogleMapStyleKind.allCases) { s in
                    Text(s.displayName).tag(s)
                }
            }

            if settings.googleStyle == .custom {
                Text(L.customJSONLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $settings.googleCustomJSON)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
        } header: {
            Text(L.mapStyle)
        } footer: {
            Text(settings.googleStyle == .custom ? L.customJSONFooter : L.stylePresetFooter)
        }
    }

    private var threeDSection: some View {
        Section {
            Toggle(L.googleBuildings3D, isOn: $settings.useGoogleBuilding3D)
        } footer: {
            Text(L.googleBuildings3DFooter)
        }
    }

    private var helpSection: some View {
        Section {
            Link(destination: URL(string: "https://console.cloud.google.com/google/maps-apis/start")!) {
                Label(L.openGoogleConsole, systemImage: "arrow.up.right.square")
            }
            Link(destination: URL(string: "https://developers.google.com/maps/documentation/style-reference")!) {
                Label(L.openStyleDocs, systemImage: "arrow.up.right.square")
            }
        } header: {
            Text(L.help)
        }
    }
}
