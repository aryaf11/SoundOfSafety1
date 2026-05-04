import Foundation

struct URLCheckResult: Codable, Equatable, Sendable {
    let isSafe: Bool
    let confidence: Double
    let reasons: [String]

    enum CodingKeys: String, CodingKey {
        case isSafe = "is_safe"
        case confidence
        case reasons
    }
}

struct CheckURLRequest: Codable, Sendable {
    let url: String
}
