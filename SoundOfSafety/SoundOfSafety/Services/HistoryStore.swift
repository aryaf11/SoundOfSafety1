import Foundation

@Observable
final class HistoryStore {
    static let shared = HistoryStore()

    private let key = "sos.history.entries"
    private let defaults = UserDefaults.standard

    private(set) var entries: [HistoryEntry] = []

    private init() {
        load()
    }

    func add(url: String, result: URLCheckResult) {
        let entry = HistoryEntry(
            id: UUID(),
            url: url,
            isSafe: result.isSafe,
            confidence: result.confidence,
            reasons: result.reasons,
            checkedAt: Date()
        )
        entries.insert(entry, at: 0)
        if entries.count > 200 {
            entries = Array(entries.prefix(200))
        }
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        entries = []
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }
}
