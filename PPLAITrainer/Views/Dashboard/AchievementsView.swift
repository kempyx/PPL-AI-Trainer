import SwiftUI

struct AchievementsView: View {
    @Environment(\.dependencies) private var deps
    @State private var achievements: [AchievementDefinition] = AchievementDefinition.allCases
    @State private var unlockedIds: Set<String> = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(achievements, id: \.rawValue) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: unlockedIds.contains(achievement.rawValue)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .onAppear {
            loadAchievements()
        }
    }
    
    private func loadAchievements() {
        guard let deps = deps else { return }
        achievements = AchievementDefinition.allCases
        unlockedIds = Set((try? deps.databaseManager.fetchAchievements().map(\.id)) ?? [])
    }
}

struct AchievementCard: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundColor(isUnlocked ? .yellow : .secondary)
            }
            
            VStack(spacing: 4) {
                Text(achievement.displayName)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(AppCornerRadius.medium)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
}
