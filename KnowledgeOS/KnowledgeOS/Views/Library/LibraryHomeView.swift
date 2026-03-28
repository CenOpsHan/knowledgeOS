import SwiftUI

struct LibraryHomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showAddBook = false
    @State private var showSearch = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Library")
                            .font(.largeTitle.bold())
                        Text("· \(viewModel.books.count) books")
                            .foregroundColor(Theme.textTertiary)
                        Spacer()
                        Menu {
                            Button("Recent") { viewModel.sortBy = "recent" }
                            Button("A-Z") { viewModel.sortBy = "az" }
                            Button("Rating") { viewModel.sortBy = "rating" }
                        } label: {
                            Text(viewModel.sortBy.capitalized)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["all", "reading", "completed", "shelved"], id: \.self) { status in
                                Button {
                                    viewModel.statusFilter = status
                                } label: {
                                    Text(status.capitalized)
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(viewModel.statusFilter == status ? Theme.accent : .clear)
                                        .background(viewModel.statusFilter == status ? AnyShapeStyle(.clear) : AnyShapeStyle(Theme.glassMaterial), in: Capsule())
                                        .foregroundColor(viewModel.statusFilter == status ? .white : Theme.textSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Book grid
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.filteredBooks.isEmpty {
                        VStack(spacing: 16) {
                            Text("Your library is empty")
                                .foregroundColor(Theme.textSecondary)
                            Button("Add your first book") { showAddBook = true }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.accent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredBooks) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookCardView(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }

            // FAB
            Button { showAddBook = true } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Theme.accent)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("KnowledgeOS")
                    .font(.system(.headline, design: .monospaced))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView()
                .environmentObject(authService)
        }
        .onAppear {
            if let userId = authService.userId {
                viewModel.subscribe(userId: userId)
            }
        }
        .onDisappear {
            viewModel.unsubscribe()
        }
    }
}
