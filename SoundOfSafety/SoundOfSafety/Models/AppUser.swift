import Foundation

struct AppUser: Codable, Equatable, Sendable {
    let id: UUID
    var username: String
    var email: String
}
