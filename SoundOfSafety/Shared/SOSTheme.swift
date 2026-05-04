import SwiftUI

enum SOSTheme {
    static let background = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.black : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
    })

    static let primaryText = Color.primary

    static let safeGreen = Color(red: 0.0, green: 0.55, blue: 0.25)
    static let unsafeRed = Color(red: 0.75, green: 0.05, blue: 0.08)

    static let accent = Color(red: 0.0, green: 0.35, blue: 0.65)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)

    static let minimumButtonHeight: CGFloat = 52
}

struct LogoMark: View {
    var accessibilityLabel: String = String(localized: "Sound of Safety, shield and sound waves emblem")

    var body: some View {
        ZStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(SOSTheme.accent)
                .accessibilityHidden(true)
            Image(systemName: "waveform")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.primary)
                .offset(y: 22)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}
