import SwiftUI

struct DailyGoalView: View {
    let answeredToday: Int
    let target: Int
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(answeredToday) / Double(target), 1.0)
    }
    
    private var isComplete: Bool {
        answeredToday >= target
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "target")
                    .foregroundColor(isComplete ? .green : .blue)
                Text("Daily Goal")
                    .font(.headline)
                Spacer()
                Text("\(answeredToday) / \(target)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isComplete ? .green : .primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(isComplete ? Color.green : Color.blue)
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
        }
        .padding()
        .cardStyle()
    }
}
