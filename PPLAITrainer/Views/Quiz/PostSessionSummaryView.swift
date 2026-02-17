import SwiftUI

struct PostSessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let summary: SessionSummary
    
    private var scorePercentage: Int {
        guard summary.questionsAnswered > 0 else { return 0 }
        return Int((Double(summary.correctAnswers) / Double(summary.questionsAnswered)) * 100)
    }
    
    private var scoreColor: Color {
        if scorePercentage >= 80 { return .green }
        if scorePercentage >= 60 { return .orange }
        return .red
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(scoreColor)
                    
                    Text("Session Complete!")
                        .font(.title.weight(.bold))
                    
                    VStack(spacing: 12) {
                        Text("\(scorePercentage)%")
                            .font(.system(size: 52, weight: .bold).monospacedDigit())
                            .foregroundColor(scoreColor)
                        
                        Text("\(summary.correctAnswers) / \(summary.questionsAnswered) correct")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                    .cornerRadius(14)
                    
                    VStack(spacing: 16) {
                        statRow(icon: "star.fill", label: "XP Earned", value: "+\(summary.xpEarned)")
                        statRow(icon: "flame.fill", label: "Streak", value: "\(summary.currentStreak)")
                        statRow(icon: "percent", label: "Accuracy", value: "\(Int(summary.accuracy * 100))%")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(14)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
