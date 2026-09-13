import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}
