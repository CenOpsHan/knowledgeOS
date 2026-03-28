import SwiftUI
import MarkdownUI

struct SkillDetailView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = SkillDetailViewModel()

    let skill: Skill
    @State private var expandedSections: Set<String> = []
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    Text(skill.icon)
                        .font(.system(size: 48))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(skill.name)
                            .font(.title2.bold())
                        Text(skill.description)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // Sections
                ForEach(skill.sections) { section in
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
            .padding()
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) { showDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Delete Skill?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                guard let userId = authService.userId, let id = skill.id else { return }
                Task {
                    try? await FirestoreService().deleteSkill(userId: userId, skillId: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            viewModel.loadSkill(skill)
            expandedSections = Set(skill.sections.map(\.id))
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
