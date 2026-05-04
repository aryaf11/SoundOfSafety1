import SwiftUI

struct URLCheckView: View {
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var result: URLCheckResult?
    @State private var errorMessage: String?
    @State private var feedbackHint: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Check a link")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                TextField(String(localized: "Paste or type a web address"), text: $urlText, axis: .vertical)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineLimit(3 ... 6)
                    .padding(16)
                    .background(SOSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel(String(localized: "URL to check"))

                Button {
                    Task { await check() }
                } label: {
                    Text("Check URL")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(SOSTheme.accent)
                .disabled(isLoading)
                .accessibilityHint(String(localized: "Analyzes the link with your security service."))

                if isLoading {
                    ProgressView(String(localized: "Checking link…"))
                        .accessibilityLabel(String(localized: "Checking link"))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundStyle(SOSTheme.unsafeRed)
                        .accessibilityLabel(errorMessage)
                }

                if let result {
                    ResultCard(result: result, urlText: urlText)
                    feedbackRow(for: result)
                }

                if let feedbackHint {
                    Text(feedbackHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(feedbackHint)
                }
            }
            .padding()
        }
        .background(SOSTheme.background)
    }

    @MainActor
    private func check() async {
        errorMessage = nil
        feedbackHint = nil
        result = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let r = try await URLCheckClient().check(urlString: urlText)
            result = r
            HistoryStore.shared.add(url: urlText, result: r)
            SpeechService.shared.speakSafetyResult(isSafe: r.isSafe)
        } catch let e as LocalizedError {
            errorMessage = e.errorDescription ?? e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func feedbackRow(for result: URLCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Was this result correct?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                Button {
                    FeedbackStore.shared.submit(url: urlText, reportedSafe: true)
                    feedbackHint = String(localized: "Thanks — your feedback was saved.")
                } label: {
                    Label(String(localized: "Looks safe"), systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.bordered)
                .tint(SOSTheme.safeGreen)

                Button {
                    FeedbackStore.shared.submit(url: urlText, reportedSafe: false)
                    feedbackHint = String(localized: "Thanks — your feedback was saved.")
                } label: {
                    Label(String(localized: "Looks unsafe"), systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity, minHeight: SOSTheme.minimumButtonHeight)
                }
                .buttonStyle(.bordered)
                .tint(SOSTheme.unsafeRed)
            }
        }
        .padding(.top, 8)
    }
}

private struct ResultCard: View {
    let result: URLCheckResult
    let urlText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .accessibilityLabel(
                    String(localized: "Confidence \(Int((result.confidence * 100).rounded())) percent")
                )

            if !result.reasons.isEmpty {
                Text("Reasons")
                    .font(.headline)
                    .padding(.top, 4)
                ForEach(Array(result.reasons.enumerated()), id: \.offset) { _, reason in
                    Label(reason, systemImage: "info.circle")
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SOSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
