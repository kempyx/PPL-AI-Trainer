import SwiftUI

struct AchievementsView: View {
    @Environment(\.dependencies) private var deps
    @State private var achievements: [AchievementDefinition] = AchievementDefinition.allCases
    @State private var unlockedById: [String: Achievement] = [:]

    private var unlockedCount: Int {
        unlockedById.count
    }

    private var totalCount: Int {
        achievements.count
    }

    private var unlockProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 16) {
                    ForEach(achievements, id: \.rawValue) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            unlockedAt: unlockedById[achievement.rawValue]?.unlockedAt
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
        .onAppear {
            loadAchievements()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Badge Progress", systemImage: "rosette")
                    .font(.headline)
                Spacer()
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: unlockProgress)
                .tint(.yellow)

            Text("Locked badges show the exact requirement, so you always know what to work on next.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
    
    private func loadAchievements() {
        guard let deps = deps else { return }
        achievements = AchievementDefinition.allCases
        let unlocked = (try? deps.databaseManager.fetchAchievements()) ?? []
        unlockedById = Dictionary(uniqueKeysWithValues: unlocked.map { ($0.id, $0) })
    }
}

struct AchievementCard: View {
    let achievement: AchievementDefinition
    let unlockedAt: Date?

    private var isUnlocked: Bool {
        unlockedAt != nil
    }

    private static let unlockedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
                
                Text(isUnlocked ? "Earned: \(achievement.description)" : "To earn: \(achievement.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let unlockedAt {
                Label("Unlocked \(Self.unlockedDateFormatter.string(from: unlockedAt))", systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12), in: Capsule())
            } else {
                Label("Locked", systemImage: "lock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6), in: Capsule())
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
