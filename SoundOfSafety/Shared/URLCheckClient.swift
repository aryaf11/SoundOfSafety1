import Foundation

enum URLCheckError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "That does not look like a valid web address.")
        case .invalidResponse:
            return String(localized: "The server returned an unexpected response.")
        case .server(let code):
            return String(localized: "Server error (code \(code)).")
        case .decoding:
            return String(localized: "Could not read the safety report.")
        }
    }
}

/// Calls `POST /check-url` with JSON body `{ "url": "..." }`.
struct URLCheckClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func check(urlString: String) async throws -> URLCheckResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let normalized = normalizeURLString(trimmed),
              URL(string: normalized) != nil else {
            throw URLCheckError.invalidURL
        }

        let base = AppConfiguration.apiBaseURL
        let endpoint = base.appendingPathComponent("check-url")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = CheckURLRequest(url: normalized)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLCheckError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw URLCheckError.server(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(URLCheckResult.self, from: data)
        } catch {
            throw URLCheckError.decoding
        }
    }

    private func normalizeURLString(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        if t.hasPrefix("http://") || t.hasPrefix("https://") { return t }
        return "https://\(t)"
    }
}
