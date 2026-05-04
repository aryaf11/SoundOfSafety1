import SwiftUI

struct AuthFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink(String(localized: "Log in")) {
                        LoginView()
                            .navigationTitle("Log in")
                    }
                    .accessibilityLabel(String(localized: "Log in to an existing account"))

                    NavigationLink(String(localized: "Sign up")) {
                        SignUpView(path: $path)
                            .navigationTitle("Sign up")
                    }
                    .accessibilityLabel(String(localized: "Create a new account"))
                }
            }
            .navigationTitle("Sound of Safety")
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .otp(let email):
                    OTPVerificationView(email: email)
                        .navigationTitle("Verify")
                }
            }
        }
    }
}
