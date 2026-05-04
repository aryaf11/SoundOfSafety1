import Foundation

struct UserFeedback: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    let url: String
    let reportedSafe: Bool
    let createdAt: Date
}
