import SwiftUI

struct KnowledgePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onLink: ([String], [String]) -> Void
    let linkedExtractIds: [String]
    let linkedSynthesisIds: [String]

    @State private var selectedExtracts: Set<String> = []
    @State private var selectedSyntheses: Set<String> = []
    @State private var searchText = ""

    // These would be populated from view models in real app
    // Simplified for demonstration
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search...", text: $searchText)
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(Theme.inputRadius)
                    .padding()

                Text("Select extracts and syntheses to link")
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Theme.bg)
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
    }
}
