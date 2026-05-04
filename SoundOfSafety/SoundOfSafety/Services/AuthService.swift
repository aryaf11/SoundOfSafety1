import Foundation
import CryptoKit

@Observable
final class AuthService {
    static let shared = AuthService()

    private let userDefaults = UserDefaults.standard
    private let kVerifiedEmails = "sos.verified.emails"
    private let kPendingOTP = "sos.pending.otp"
    private let kPendingEmail = "sos.pending.email"
    private let kPendingUserData = "sos.pending.user"

    private let keychainService = "com.soundofsafety.app"
    private let passwordAccount = "user.password"

    /// Last logged-in session
    private let kSessionUser = "sos.session.user"

    var currentUser: AppUser?
    var isAuthenticated: Bool { currentUser != nil }

    private init() {
        loadSession()
    }

    private func loadSession() {
        guard let data = userDefaults.data(forKey: kSessionUser),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else {
            currentUser = nil
            return
        }
        currentUser = user
    }

    private func persistSession(_ user: AppUser?) {
        if let user, let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: kSessionUser)
        } else {
            userDefaults.removeObject(forKey: kSessionUser)
        }
    }

    /// Stores SHA256 hash of password in Keychain (no plaintext).
    func signUp(username: String, email: String, password: String, confirmPassword: String) throws {
        guard password == confirmPassword else {
            throw AuthError.passwordMismatch
        }
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        let emailNorm = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard emailNorm.contains("@") else {
            throw AuthError.invalidEmail
        }

        if isEmailRegistered(emailNorm) {
            throw AuthError.emailInUse
        }

        let otp = String(format: "%06d", Int.random(in: 0 ... 999_999))
        userDefaults.set(otp, forKey: kPendingOTP)
        userDefaults.set(emailNorm, forKey: kPendingEmail)
        let user = AppUser(id: UUID(), username: username.trimmingCharacters(in: .whitespacesAndNewlines), email: emailNorm)
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: kPendingUserData)
        }
        userDefaults.synchronize()

        let hash = Self.hashPassword(password)
        try KeychainHelper.save(hash, service: keychainService, account: passwordAccount + ".\(emailNorm)")
    }

    /// For demo: OTP is stored locally. In production, verify with your backend.
    func peekDemoOTP() -> String? {
        userDefaults.string(forKey: kPendingOTP)
    }

    func verifyOTP(_ code: String) throws {
        guard let expected = userDefaults.string(forKey: kPendingOTP),
              let data = userDefaults.data(forKey: kPendingUserData),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else {
            throw AuthError.noPendingVerification
        }
        let email = userDefaults.string(forKey: kPendingEmail) ?? user.email
        guard code == expected else {
            throw AuthError.invalidOTP
        }
        guard user.email == email else {
            throw AuthError.invalidOTP
        }

        var verified = Set(userDefaults.stringArray(forKey: kVerifiedEmails) ?? [])
        verified.insert(email)
        userDefaults.set(Array(verified), forKey: kVerifiedEmails)

        currentUser = user
        persistSession(user)
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: profileKey(for: email))
        }
        userDefaults.removeObject(forKey: kPendingOTP)
        userDefaults.removeObject(forKey: kPendingEmail)
        userDefaults.removeObject(forKey: kPendingUserData)
    }

    func login(email: String, password: String) throws {
        let emailNorm = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard isEmailVerified(emailNorm) else {
            throw AuthError.emailNotVerified
        }
        let stored = try KeychainHelper.read(service: keychainService, account: passwordAccount + ".\(emailNorm)")
        guard let stored else { throw AuthError.invalidCredentials }
        let hash = Self.hashPassword(password)
        guard hash == stored else { throw AuthError.invalidCredentials }

        let user: AppUser
        if let data = userDefaults.data(forKey: profileKey(for: emailNorm)),
           let profile = try? JSONDecoder().decode(AppUser.self, from: data) {
            user = profile
        } else {
            user = AppUser(
                id: UUID(),
                username: emailNorm.split(separator: "@").first.map(String.init) ?? "User",
                email: emailNorm
            )
        }
        currentUser = user
        persistSession(user)
    }

    func logout() {
        currentUser = nil
        persistSession(nil)
    }

    private func profileKey(for email: String) -> String {
        "sos.profile.\(email)"
    }

    func resendOTP() {
        let newOtp = String(format: "%06d", Int.random(in: 0 ... 999_999))
        userDefaults.set(newOtp, forKey: kPendingOTP)
    }

    private func isEmailRegistered(_ email: String) -> Bool {
        (try? KeychainHelper.read(service: keychainService, account: passwordAccount + ".\(email)")) != nil
    }

    private func isEmailVerified(_ email: String) -> Bool {
        let verified = Set(userDefaults.stringArray(forKey: kVerifiedEmails) ?? [])
        return verified.contains(email)
    }

    private static func hashPassword(_ password: String) -> Data {
        let digest = SHA256.hash(data: Data(password.utf8))
        return Data(digest)
    }
}

enum AuthError: LocalizedError {
    case passwordMismatch
    case weakPassword
    case invalidEmail
    case emailInUse
    case invalidOTP
    case noPendingVerification
    case invalidCredentials
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .passwordMismatch:
            return String(localized: "Passwords do not match.")
        case .weakPassword:
            return String(localized: "Password must be at least 8 characters.")
        case .invalidEmail:
            return String(localized: "Please enter a valid email address.")
        case .emailInUse:
            return String(localized: "This email is already registered.")
        case .invalidOTP:
            return String(localized: "Invalid verification code.")
        case .noPendingVerification:
            return String(localized: "No pending verification. Please sign up again.")
        case .invalidCredentials:
            return String(localized: "Invalid email or password.")
        case .emailNotVerified:
            return String(localized: "Please complete email verification before logging in.")
        }
    }
}
