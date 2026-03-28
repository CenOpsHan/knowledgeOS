import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TopicDetailViewModel()

    let tagName: String
    @State private var filter = "all"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tagName)
                    .font(.title2.bold())

                Text("\(viewModel.extracts.count) extracts · \(viewModel.syntheses.count) syntheses")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: 8) {
                    ForEach(["all", "extracts", "syntheses"], id: \.self) { f in
                        Button {
                            filter = f
                        } label: {
                            Text(f == "all" ? "All" : f.capitalized)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(filter == f ? Theme.accent : Theme.surfaceElevated)
                                .foregroundColor(filter == f ? .white : Theme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if filter != "syntheses" {
                    ForEach(viewModel.extracts) { extract in
                        NavigationLink(destination: ExtractDetailView(extract: extract, bookId: extract.bookId)) {
                            ExtractCardView(extract: extract)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if filter != "extracts" {
                    ForEach(viewModel.syntheses) { synthesis in
                        NavigationLink(destination: SynthesisDetailView(synthesis: synthesis, bookId: synthesis.bookId)) {
                            SynthesisCardView(synthesis: synthesis)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userId = authService.userId {
                viewModel.subscribe(userId: userId, tagName: tagName)
            }
        }
        .onDisappear { viewModel.unsubscribe() }
    }
}
