import SwiftUI

struct BadgeUnlockModal: View {
    let achievement: AchievementDefinition
    let onDismiss: () -> Void
    let onViewAll: (() -> Void)?
    
    @State private var scale: CGFloat = 0.5

    init(
        achievement: AchievementDefinition,
        onDismiss: @escaping () -> Void,
        onViewAll: (() -> Void)? = nil
    ) {
        self.achievement = achievement
        self.onDismiss = onDismiss
        self.onViewAll = onViewAll
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("Achievement Unlocked!")
                    .font(.title2.weight(.bold))
                
                Text(achievement.displayName)
                    .font(.title3.weight(.semibold))
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let onViewAll {
                    Button("View All Badges") {
                        onViewAll()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(30)
            .cardStyle()
            .shadow(radius: 20)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
        }
    }
}

#Preview {
    BadgeUnlockModal(
        achievement: .firstSolo,
        onDismiss: {}
    )
}
