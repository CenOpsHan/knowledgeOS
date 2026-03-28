import SwiftUI

struct CreateSkillView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var icon = "📚"
    @State private var sections: [SkillSection] = [SkillSection()]
    @State private var isSaving = false

    private let firestoreService = FirestoreService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        TextField("📚", text: $icon)
                            .font(.system(size: 36))
                            .frame(width: 64, height: 64)
                            .multilineTextAlignment(.center)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(Theme.cardRadius)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))

                        VStack(spacing: 8) {
                            TextField("e.g. SEO Playbook", text: $name)
                                .font(.headline)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                            TextField("What is this skill about?", text: $description)
                                .font(.subheadline)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))
                        }
                    }

                    ForEach(sections.indices, id: \.self) { index in
                        VStack(spacing: 8) {
                            TextField("Section title", text: $sections[index].title)
                                .font(.subheadline.weight(.semibold))
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))

                            TextEditor(text: $sections[index].content)
                                .font(.body)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(Theme.inputRadius)
                                .overlay(RoundedRectangle(cornerRadius: Theme.inputRadius).stroke(Theme.border, lineWidth: 1))
                        }
                        .padding(Theme.cardPadding)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(Theme.cardRadius)
                    }

                    Button {
                        sections.append(SkillSection(order: sections.count))
                    } label: {
                        Label("Add Another Section", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.surfaceElevated)
                            .cornerRadius(Theme.cardRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cardRadius)
                                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                            )
                    }

                    Button { save() } label: {
                        Text(isSaving ? "Creating..." : "Create Skill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.accent.opacity(0.5) : Theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.inputRadius)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("New Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard let userId = authService.userId else { return }
        isSaving = true
        Task {
            let skill = Skill(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description,
                icon: icon.isEmpty ? "📚" : String(icon.prefix(2)),
                sections: sections.enumerated().map { i, s in
                    var section = s
                    section.order = i
                    return section
                }
            )
            _ = try? await firestoreService.createSkill(userId: userId, skill: skill)
            dismiss()
        }
    }
}
