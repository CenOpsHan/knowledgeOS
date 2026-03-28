import SwiftUI

struct SkillsHomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = SkillsViewModel()
    @State private var showCreateSkill = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Skills")
                        .font(.title2.bold())
                    + Text(" · \(viewModel.skills.count)")
                        .foregroundColor(Theme.textTertiary)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.skills.isEmpty {
                        VStack(spacing: 16) {
                            Text("No skills yet. Build your first knowledge module.")
                                .foregroundColor(Theme.textSecondary)
                            Button("Create Skill") { showCreateSkill = true }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.accent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ForEach(viewModel.skills) { skill in
                            NavigationLink(destination: SkillDetailView(skill: skill)) {
                                skillCard(skill)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }

            Button { showCreateSkill = true } label: {
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
        .background(Theme.bg)
        .sheet(isPresented: $showCreateSkill) {
            CreateSkillView()
                .environmentObject(authService)
        }
        .onAppear {
            if let userId = authService.userId {
                viewModel.subscribe(userId: userId)
            }
        }
        .onDisappear { viewModel.unsubscribe() }
    }

    private func skillCard(_ skill: Skill) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(skill.icon)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(skill.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)

                let totalLinked = skill.sections.reduce(0) {
                    $0 + ($1.linkedExtractIds.count) + ($1.linkedSynthesisIds.count)
                }
                Text("\(skill.sections.count) sections · \(totalLinked) linked items")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
    }
}
