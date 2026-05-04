import Foundation

@Observable
final class FeedbackStore {
    static let shared = FeedbackStore()

    private let key = "sos.user.feedback"
    private let defaults = UserDefaults.standard

    private(set) var items: [UserFeedback] = []

    private init() {
        load()
    }

    func submit(url: String, reportedSafe: Bool) {
        let fb = UserFeedback(id: UUID(), url: url, reportedSafe: reportedSafe, createdAt: Date())
        items.insert(fb, at: 0)
        if items.count > 100 { items = Array(items.prefix(100)) }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UserFeedback].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }
}
