import SwiftUI
import UIKit

struct RootView: View {
    @Bindable private var auth = AuthService.shared
    @Bindable private var clipboard = ClipboardMonitor.shared

    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
            } else if auth.isAuthenticated {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .tint(SOSTheme.accent)
        .preferredColorScheme(nil)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ClipboardMonitor.shared.applicationBecameActive()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            ClipboardMonitor.shared.checkPasteboard()
        }
        .alert(
            String(localized: "Unsafe link copied"),
            isPresented: Binding(
                get: { clipboard.alertResult != nil },
                set: { if !$0 { clipboard.dismissAlert() } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {
                clipboard.dismissAlert()
            }
        } message: {
            if let url = clipboard.alertURL, let result = clipboard.alertResult {
                Text(
                    String(
                        localized: "The clipboard may contain an unsafe link: \(url). Confidence about \(Int((result.confidence * 100).rounded())) percent."
                    )
                )
            }
        }
    }
}
