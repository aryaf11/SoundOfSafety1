import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            SOSTheme.background
                .ignoresSafeArea()
            VStack(spacing: 28) {
                LogoMark()
                Text("Sound of Safety")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                ProgressView()
                    .accessibilityLabel(String(localized: "Loading"))
            }
            .padding()
        }
    }
}
