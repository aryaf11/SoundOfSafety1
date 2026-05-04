import SwiftUI

struct ShareCheckView: View {
    let urlString: String
    var onOpenLink: (URL) -> Void
    var onCancel: () -> Void

    @State private var result: URLCheckResult?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(urlString)
                        .font(.body)
                        .lineLimit(4)
                        .accessibilityLabel(String(localized: "Shared link: \(urlString)"))

                    if isLoading {
                        ProgressView(String(localized: "Checking link…"))
                            .accessibilityLabel(String(localized: "Checking link"))
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(SOSTheme.unsafeRed)
                            .accessibilityLabel(errorMessage)
                    } else if let result {
                        Text(result.isSafe ? "SAFE" : "UNSAFE")
                            .font(.title.weight(.heavy))
                            .foregroundStyle(result.isSafe ? SOSTheme.safeGreen : SOSTheme.unsafeRed)
                            .accessibilityLabel(
                                result.isSafe
                                    ? String(localized: "Result: safe")
                                    : String(localized: "Result: unsafe")
                            )

                        Text(String(localized: "Confidence: \(Int((result.confidence * 100).rounded()))%"))
                            .font(.headline)

                        if !result.reasons.isEmpty {
                            ForEach(Array(result.reasons.enumerated()), id: \.offset) { _, reason in
                                Label(reason, systemImage: "info.circle")
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            if let u = URL(string: urlString) ?? normalizedURL(from: urlString) {
                                onOpenLink(u)
                            }
                        } label: {
                            Text("Open Link")
                                .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SOSTheme.accent)
                        .disabled(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(role: .cancel) {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(SOSTheme.background)
            .navigationTitle("Sound of Safety")
        }
        .task {
            guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = String(localized: "No URL was shared.")
                isLoading = false
                return
            }
            await runCheck()
        }
    }

    private func runCheck() async {
        do {
            let r = try await URLCheckClient().check(urlString: urlString)
            result = r
            if !r.isSafe {
                SpeechService.shared.speakSafetyResult(isSafe: false)
            } else {
                SpeechService.shared.speakSafetyResult(isSafe: true)
            }
        } catch let e as LocalizedError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func normalizedURL(from text: String) -> URL? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("http"), let u = URL(string: t) { return u }
        return URL(string: "https://\(t)")
    }
}
