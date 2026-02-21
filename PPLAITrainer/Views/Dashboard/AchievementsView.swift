import SwiftUI

struct AchievementsView: View {
    @Environment(\.dependencies) private var deps
    @State private var achievements: [Achievement] = []
    @State private var unlockedIds: Set<String> = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: unlockedIds.contains(achievement.id)
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
        achievements = Achievement.allAchievements
        unlockedIds = Set((try? deps.databaseManager.fetchUnlockedAchievements().map(\.id)) ?? [])
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundColor(isUnlocked ? achievement.color : .secondary)
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if !isUnlocked {
                ProgressView(value: achievement.progress, total: 1.0)
                    .tint(.blue)
                    .padding(.horizontal, 8)
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
