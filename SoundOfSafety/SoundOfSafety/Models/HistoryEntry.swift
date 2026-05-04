import Foundation

struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    let url: String
    let isSafe: Bool
    let confidence: Double
    let reasons: [String]
    let checkedAt: Date
}
