import SwiftUI

struct OTPVerificationView: View {
    let email: String

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var demoHint: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Verify email")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Text(String(localized: "Enter the 6-digit code sent to your email."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "Enter the six digit code sent to your email."))

                TextField(String(localized: "Verification code"), text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .padding(14)
                    .background(SOSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(String(localized: "Verification code"))
                    #if DEBUG
                    .onAppear {
                        demoHint = AuthService.shared.peekDemoOTP()
                    }
                #endif

                #if DEBUG
                if let demoHint {
                    Text(String(localized: "Developer build: code is \(demoHint)"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(String(localized: "Developer only: the code is \(demoHint)"))
                }
                #endif

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.unsafeRed)
                        .accessibilityLabel(errorMessage)
                }

                Button {
                    verify()
                } label: {
                    Text("Verify")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(SOSTheme.accent)

                Button {
                    AuthService.shared.resendOTP()
                    #if DEBUG
                    demoHint = AuthService.shared.peekDemoOTP()
                    #endif
                } label: {
                    Text("Resend code")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.bordered)
                .accessibilityHint(String(localized: "Requests a new verification code."))
            }
            .padding()
        }
        .background(SOSTheme.background)
    }

    private func verify() {
        errorMessage = nil
        do {
            try AuthService.shared.verifyOTP(code.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch let e as LocalizedError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
