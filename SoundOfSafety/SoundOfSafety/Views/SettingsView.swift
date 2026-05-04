import SwiftUI

struct SettingsView: View {
    @State private var apiBaseString = ""
    @State private var clipboardOn = true
    @State private var saveMessage: String?

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "API base URL"), text: $apiBaseString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel(String(localized: "API base URL, without trailing slash"))

                Button(String(localized: "Save API URL")) {
                    let t = apiBaseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let u = URL(string: t), u.scheme == "https" || u.scheme == "http" {
                        AppConfiguration.apiBaseURL = u
                        saveMessage = String(localized: "Saved.")
                    } else {
                        saveMessage = String(localized: "Enter a valid http or https URL.")
                    }
                }
                .accessibilityHint(String(localized: "Stores the base URL used for link checking."))

                if let saveMessage {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Toggle(String(localized: "Monitor clipboard for links"), isOn: $clipboardOn)
                    .accessibilityHint(String(localized: "When enabled, copied links are checked automatically when you return to the app."))
                    .onChange(of: clipboardOn) { _, v in
                        AppConfiguration.clipboardMonitoringEnabled = v
                    }
            } header: {
                Text("Security")
            }

            Section {
                Button(String(localized: "Log out"), role: .destructive) {
                    AuthService.shared.logout()
                }
                .accessibilityLabel(String(localized: "Log out of your account"))
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            apiBaseString = AppConfiguration.apiBaseURL.absoluteString
            clipboardOn = AppConfiguration.clipboardMonitoringEnabled
        }
    }
}
