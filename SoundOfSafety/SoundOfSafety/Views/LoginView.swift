import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Log in")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                LabeledContent {
                    TextField(String(localized: "Email"), text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(SOSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } label: {
                    Text("Email")
                }
                .accessibilityElement(children: .combine)

                SecureField(String(localized: "Password"), text: $password)
                    .textContentType(.password)
                    .padding(14)
                    .background(SOSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(String(localized: "Password"))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.unsafeRed)
                        .accessibilityLabel(errorMessage)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Text("Log in")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(SOSTheme.accent)
                .accessibilityHint(String(localized: "Verifies your email and password."))
            }
            .padding()
        }
        .background(SOSTheme.background)
    }

    @MainActor
    private func submit() async {
        errorMessage = nil
        do {
            try AuthService.shared.login(email: email, password: password)
        } catch let e as LocalizedError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
