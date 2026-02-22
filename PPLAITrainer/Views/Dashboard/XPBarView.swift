import SwiftUI

struct XPBarView: View {
    @ScaledMetric(relativeTo: .body) private var barHeight = 12
    let totalXP: Int
    let currentLevel: PilotLevel
    let progress: Double
    
    @State private var animatedProgress: Double = 0
    
    private var nextLevel: PilotLevel? {
        PilotLevel.nextLevel(for: totalXP)
    }
    
    var body: some View {
        NavigationLink {
            AchievementsView()
        } label: {
            achievementContent
        }
        .buttonStyle(.plain)
    }
    
    private var achievementContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: currentLevel.icon)
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentLevel.title)
                        .font(.headline)
                    if let next = nextLevel {
                        Text("\(totalXP) / \(next.minXP) XP to \(next.title)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(totalXP) XP · Max Rank")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: barHeight)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            }
            
            if let next = nextLevel {
                let xpNeeded = next.minXP - totalXP
                Text("\(xpNeeded) XP to \(next.title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Max Level!")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            Divider()

            HStack(spacing: 8) {
                Label("View badges and goals", systemImage: "rosette")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    XPBarView(
        totalXP: 1250,
        currentLevel: PilotLevel.level(for: 1250),
        progress: 0.65
    )
    .environment(\.dependencies, Dependencies.preview)
}
