import SwiftUI

struct MainTabView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            TabView {
                SessionListView()
                    .tabItem {
                        Label("牌局", systemImage: "suit.club.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar.fill")
                    }
            }
            .tint(.appAccent)
        }
    }
}
