import SwiftUI
import UIKit

@Observable
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    var alertResult: URLCheckResult?
    var alertURL: String?

    private var lastAnalyzedString: String?

    func applicationBecameActive() {
        checkPasteboard()
    }

    func checkPasteboard() {
        guard AppConfiguration.clipboardMonitoringEnabled else { return }
        let pb = UIPasteboard.general
        guard pb.hasStrings, let text = pb.string else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.looksLikeURL(trimmed) else { return }
        if trimmed == lastAnalyzedString { return }

        Task { @MainActor in
            await analyze(trimmed)
        }
    }

    func dismissAlert() {
        alertResult = nil
        alertURL = nil
    }

    @MainActor
    private func analyze(_ text: String) async {
        do {
            let client = URLCheckClient()
            let result = try await client.check(urlString: text)
            lastAnalyzedString = text
            if !result.isSafe {
                alertResult = result
                alertURL = text
                SpeechService.shared.speakSafetyResult(isSafe: false)
            }
        } catch {
            // Ignore background clipboard errors
        }
    }

    private static func looksLikeURL(_ s: String) -> Bool {
        let t = s.lowercased()
        if t.hasPrefix("http://") || t.hasPrefix("https://") { return true }
        return t.contains(".") && t.count > 4 && !t.contains(" ")
    }
}
