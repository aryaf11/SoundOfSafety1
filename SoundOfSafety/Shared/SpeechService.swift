import AVFoundation
import Foundation

final class SpeechService: NSObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    func speakSafetyResult(isSafe: Bool) {
        let utterance = AVSpeechUtterance(string: isSafe ? Self.safePhrase : Self.unsafePhrase)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
            ?? AVSpeechSynthesisVoice(language: "ar")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.volume = 1.0
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static let unsafePhrase = "تحذير، هذا الرابط غير آمن"
    private static let safePhrase = "الرابط آمن"
}
