import SwiftUI
import MarkdownUI

struct SkillDetailView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = SkillDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    let skill: Skill
    @State private var expandedSections: Set<String> = []
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isEditing {
                    editingView
                } else {
                    readOnlyView
                }
            }
            .padding()
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isEditing {
                    Button("Done") {
                        guard let userId = authService.userId, let id = skill.id else { return }
                        Task { await viewModel.save(userId: userId, skillId: id) }
                    }
                    .disabled(viewModel.editName.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Menu {
                        Button { viewModel.isEditing = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDelete = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            if viewModel.isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.loadSkill(skill)
                        viewModel.isEditing = false
                    }
                }
            }
        }
        .alert("Delete Skill?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                guard let userId = authService.userId, let id = skill.id else { return }
                Task {
                    try? await FirestoreService().deleteSkill(userId: userId, skillId: id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            viewModel.loadSkill(skill)
            expandedSections = Set(skill.sections.map(\.id))
        }
    }

    // MARK: - Read-only view
    private var readOnlyView: some View {
        Group {
            // Header
            HStack(alignment: .top, spacing: 16) {
                Text(viewModel.skill?.icon ?? skill.icon)
                    .font(.system(size: 48))
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.skill?.name ?? skill.name)
                        .font(.title2.bold())
                    Text(viewModel.skill?.description ?? skill.description)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            // Sections
            ForEach(viewModel.skill?.sections ?? skill.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        toggleSection(section.id)
                    } label: {
                        HStack {
                            Text(section.title.isEmpty ? "Untitled Section" : section.title)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: expandedSections.contains(section.id) ? "chevron.down" : "chevron.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }

                    if expandedSections.contains(section.id) {
                        Markdown(section.content)
                            .markdownTheme(.gitHub)
                            .padding()
                    }
                }
                .padding(Theme.cardPadding)
                .background(Theme.surface)
                .cornerRadius(Theme.cardRadius)
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
            }
        }
    }

    // MARK: - Editing view
    private var editingView: some View {
        Group {
            // Icon + Name
            HStack(alignment: .top, spacing: 16) {
                TextField("📚", text: $viewModel.editIcon)
                    .font(.system(size: 40))
                    .frame(width: 60)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    TextField("Skill name", text: $viewModel.editName)
                        .font(.title3.weight(.semibold))
                        .padding(10)
                        .background(Theme.surface)
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                    TextField("Description", text: $viewModel.editDescription)
                        .padding(10)
                        .background(Theme.surface)
                        .cornerRadius(Theme.inputRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))
                }
            }

            // Sections
            ForEach(viewModel.editSections.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Section title", text: $viewModel.editSections[index].title)
                            .font(.headline)
                        if viewModel.editSections.count > 1 {
                            Button {
                                viewModel.removeSection(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Theme.destructive)
                            }
                        }
                    }

                    TextEditor(text: $viewModel.editSections[index].content)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(Theme.inputRadius)
                }
                .padding(Theme.cardPadding)
                .background(Theme.surface)
                .cornerRadius(Theme.cardRadius)
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
            }

            Button {
                viewModel.addSection()
            } label: {
                Label("Add Section", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.skill)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.skill.opacity(0.1))
                    .cornerRadius(Theme.cardRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .stroke(Theme.skill.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
            }
        }
    }

    private func toggleSection(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
}
