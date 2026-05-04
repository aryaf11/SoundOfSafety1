import SwiftUI

struct HistoryView: View {
    @Bindable private var history = HistoryStore.shared

    var body: some View {
        List {
            if history.entries.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "clock",
                    description: Text("Checked links will appear here.")
                )
                .accessibilityLabel(String(localized: "No history yet. Checked links will appear here."))
            } else {
                ForEach(history.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.url)
                            .font(.body)
                            .lineLimit(2)
                        Text(entry.isSafe ? "SAFE" : "UNSAFE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(entry.isSafe ? SOSTheme.safeGreen : SOSTheme.unsafeRed)
                        Text(
                            String(
                                localized: "Confidence: \(Int((entry.confidence * 100).rounded()))%"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Text(entry.checkedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
                .onDelete { indexSet in
                    HistoryStore.shared.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !history.entries.isEmpty {
                Button(String(localized: "Clear")) {
                    HistoryStore.shared.clear()
                }
                .accessibilityLabel(String(localized: "Clear all history"))
            }
        }
    }
}
