import SwiftUI
import FirebaseFirestore

struct KnowledgePickerView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let onLink: ([String], [String]) -> Void
    let linkedExtractIds: [String]
    let linkedSynthesisIds: [String]

    @State private var selectedExtracts: Set<String> = []
    @State private var selectedSyntheses: Set<String> = []
    @State private var searchText = ""
    @State private var filter = "all" // all | extracts | syntheses

    @State private var allExtracts: [Extract] = []
    @State private var allSyntheses: [Synthesis] = []
    @State private var allBooks: [Book] = []
    @State private var listeners: [ListenerRegistration] = []

    private let firestoreService = FirestoreService()

    var filteredExtracts: [Extract] {
        guard filter != "syntheses" else { return [] }
        if searchText.isEmpty { return allExtracts }
        let q = searchText.lowercased()
        return allExtracts.filter { $0.content.lowercased().contains(q) }
    }

    var filteredSyntheses: [Synthesis] {
        guard filter != "extracts" else { return [] }
        if searchText.isEmpty { return allSyntheses }
        let q = searchText.lowercased()
        return allSyntheses.filter {
            $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q)
        }
    }

    var bookMap: [String: Book] {
        Dictionary(uniqueKeysWithValues: allBooks.compactMap { b in
            guard let id = b.id else { return nil }
            return (id, b)
        })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.textTertiary)
                    TextField("Search...", text: $searchText)
                }
                .padding(10)
                .background(Color.white.opacity(0.5))
                .cornerRadius(Theme.inputRadius)
                .padding(.horizontal)
                .padding(.top, 8)

                // Filter pills
                HStack(spacing: 8) {
                    ForEach(["all", "extracts", "syntheses"], id: \.self) { f in
                        Button {
                            filter = f
                        } label: {
                            Text(f == "all" ? "All" : f.capitalized)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filter == f ? Theme.accent : Color.white.opacity(0.5))
                                .foregroundColor(filter == f ? .white : Theme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Items list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if !filteredExtracts.isEmpty {
                            Text("EXTRACTS")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Theme.textTertiary)
                                .padding(.horizontal)

                            ForEach(filteredExtracts) { extract in
                                if let id = extract.id {
                                    Button {
                                        toggleExtract(id)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedExtracts.contains(id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedExtracts.contains(id) ? Theme.accent : Theme.textTertiary)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(extract.content.prefix(80))
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .lineLimit(2)
                                                if let book = bookMap[extract.bookId] {
                                                    Text(book.title)
                                                        .font(.caption2)
                                                        .foregroundColor(Theme.textTertiary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(selectedExtracts.contains(id) ? Theme.accentDim : Color.white.opacity(0.5))
                                        .cornerRadius(Theme.inputRadius)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if !filteredSyntheses.isEmpty {
                            Text("SYNTHESES")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Theme.textTertiary)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            ForEach(filteredSyntheses) { synthesis in
                                if let id = synthesis.id {
                                    Button {
                                        toggleSynthesis(id)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedSyntheses.contains(id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedSyntheses.contains(id) ? Theme.accent : Theme.textTertiary)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(synthesis.title)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundColor(Theme.textPrimary)
                                                Text(synthesis.content.prefix(60))
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)
                                                    .lineLimit(1)
                                                if let book = bookMap[synthesis.bookId] {
                                                    Text(book.title)
                                                        .font(.caption2)
                                                        .foregroundColor(Theme.textTertiary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(selectedSyntheses.contains(id) ? Theme.accentDim : Color.white.opacity(0.5))
                                        .cornerRadius(Theme.inputRadius)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if filteredExtracts.isEmpty && filteredSyntheses.isEmpty {
                            Text("No items found")
                                .foregroundColor(Theme.textTertiary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Link Knowledge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onLink(Array(selectedExtracts), Array(selectedSyntheses))
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            selectedExtracts = Set(linkedExtractIds)
            selectedSyntheses = Set(linkedSynthesisIds)
            subscribe()
        }
        .onDisappear { unsubscribe() }
    }

    private func toggleExtract(_ id: String) {
        if selectedExtracts.contains(id) {
            selectedExtracts.remove(id)
        } else {
            selectedExtracts.insert(id)
        }
    }

    private func toggleSynthesis(_ id: String) {
        if selectedSyntheses.contains(id) {
            selectedSyntheses.remove(id)
        } else {
            selectedSyntheses.insert(id)
        }
    }

    private func subscribe() {
        guard let userId = authService.userId else { return }

        let l1 = firestoreService.subscribeBooks(userId: userId) { books in
            allBooks = books
        }
        listeners.append(l1)

        let extractsRef = Firestore.firestore()
            .collection("users").document(userId).collection("extracts")
            .order(by: "dateCreated", descending: true)
        let l2 = extractsRef.addSnapshotListener { snapshot, _ in
            let items = snapshot?.documents.compactMap { try? $0.data(as: Extract.self) } ?? []
            DispatchQueue.main.async { allExtracts = items }
        }
        listeners.append(l2)

        let synthesesRef = Firestore.firestore()
            .collection("users").document(userId).collection("syntheses")
            .order(by: "dateCreated", descending: true)
        let l3 = synthesesRef.addSnapshotListener { snapshot, _ in
            let items = snapshot?.documents.compactMap { try? $0.data(as: Synthesis.self) } ?? []
            DispatchQueue.main.async { allSyntheses = items }
        }
        listeners.append(l3)
    }

    private func unsubscribe() {
        listeners.forEach { $0.remove() }
        listeners = []
    }
}
