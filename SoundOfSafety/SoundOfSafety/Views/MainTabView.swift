import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                URLCheckView()
                    .navigationTitle("Check")
            }
            .tabItem {
                Label(String(localized: "Check"), systemImage: "checkmark.shield")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(String(localized: "History"), systemImage: "clock")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(String(localized: "Settings"), systemImage: "gearshape")
            }
        }
        .tint(SOSTheme.accent)
    }
}
