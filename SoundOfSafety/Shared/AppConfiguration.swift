import Foundation

enum AppConfiguration {
    private static let suiteName = "group.com.soundofsafety.shared"

    private enum Keys {
        static let apiBaseURL = "sos.api.base.url"
        static let clipboardMonitorEnabled = "sos.clipboard.monitor"
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var apiBaseURL: URL {
        get {
            if let s = sharedDefaults.string(forKey: Keys.apiBaseURL), let u = URL(string: s), !s.isEmpty {
                return u
            }
            return URL(string: "https://api.example.com")!
        }
        set {
            sharedDefaults.set(newValue.absoluteString, forKey: Keys.apiBaseURL)
        }
    }

    static var clipboardMonitoringEnabled: Bool {
        get { sharedDefaults.object(forKey: Keys.clipboardMonitorEnabled) as? Bool ?? true }
        set { sharedDefaults.set(newValue, forKey: Keys.clipboardMonitorEnabled) }
    }
}
