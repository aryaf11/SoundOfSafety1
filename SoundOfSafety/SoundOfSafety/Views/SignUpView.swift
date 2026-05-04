import SwiftUI

struct SignUpView: View {
    @Binding var path: NavigationPath

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create account")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Group {
                    TextField(String(localized: "Username"), text: $username)
                        .textContentType(.username)
                        .padding(14)
                        .background(SOSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel(String(localized: "Username"))

                    TextField(String(localized: "Email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(SOSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel(String(localized: "Email"))

                    SecureField(String(localized: "Password"), text: $password)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(SOSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel(String(localized: "Password"))

                    SecureField(String(localized: "Confirm password"), text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(SOSTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel(String(localized: "Confirm password"))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.unsafeRed)
                        .accessibilityLabel(errorMessage)
                }

                Button {
                    submit()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(SOSTheme.accent)
                .accessibilityHint(String(localized: "Sends a verification code to complete signup."))
            }
            .padding()
        }
        .background(SOSTheme.background)
    }

    private func submit() {
        errorMessage = nil
        do {
            try AuthService.shared.signUp(
                username: username,
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
            path.append(.otp(email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)))
        } catch let e as LocalizedError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum AuthRoute: Hashable {
    case otp(email: String)
}
