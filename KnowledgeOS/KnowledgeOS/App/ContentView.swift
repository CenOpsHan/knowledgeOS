import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryHomeView()
            }
            .tabItem {
                Image(systemName: "book")
                Text("Library")
            }
            .tag(0)

            NavigationStack {
                SkillsHomeView()
            }
            .tabItem {
                Image(systemName: "star")
                Text("Skills")
            }
            .tag(1)

            NavigationStack {
                TopicsHomeView()
            }
            .tabItem {
                Image(systemName: "tag")
                Text("Topics")
            }
            .tag(2)
        }
        .tint(Theme.accent)
        .preferredColorScheme(.light)
    }
}
