import SwiftUI

struct XPBarView: View {
    let totalXP: Int
    let currentLevel: PilotLevel
    let progress: Double
    
    @State private var animatedProgress: Double = 0
    
    private var nextLevel: PilotLevel? {
        PilotLevel.nextLevel(for: totalXP)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: currentLevel.icon)
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentLevel.title)
                        .font(.headline)
                    Text("\(totalXP) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            .frame(height: 12)
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
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
}
