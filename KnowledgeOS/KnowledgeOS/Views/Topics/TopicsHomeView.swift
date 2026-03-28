import SwiftUI

struct TopicsHomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TopicsViewModel()
    @State private var viewMode = "cloud" // cloud | list
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Topics")
                        .font(.title2.bold())
                    + Text(" · \(viewModel.tags.count)")
                        .foregroundColor(Theme.textTertiary)

                    Spacer()

                    HStack(spacing: 4) {
                        Button { viewMode = "cloud" } label: {
                            Image(systemName: "cloud")
                                .foregroundColor(viewMode == "cloud" ? Theme.accent : Theme.textTertiary)
                        }
                        Button { viewMode = "list" } label: {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewMode == "list" ? Theme.accent : Theme.textTertiary)
                        }
                    }
                }

                TextField("Filter tags...", text: $searchText)
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(Theme.inputRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                let filtered = viewModel.tags.filter {
                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if filtered.isEmpty {
                    Text("No tags yet. Start tagging your extracts and syntheses.")
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewMode == "cloud" {
                    // Tag cloud
                    FlowLayout(spacing: 8) {
                        ForEach(filtered) { tag in
                            NavigationLink(destination: TopicDetailView(tagName: tag.name)) {
                                Text(tag.name)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: tag.color).opacity(0.15))
                                    .foregroundColor(Color(hex: tag.color))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // List view
                    ForEach(filtered.sorted { $0.name < $1.name }) { tag in
                        NavigationLink(destination: TopicDetailView(tagName: tag.name)) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: tag.color))
                                    .frame(width: 12, height: 12)
                                Text(tag.name)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg)
        .onAppear {
            if let userId = authService.userId {
                viewModel.subscribe(userId: userId)
            }
        }
        .onDisappear { viewModel.unsubscribe() }
    }
}
