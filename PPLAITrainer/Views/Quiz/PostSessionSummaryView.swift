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
                    .cardStyle()
                    
                    if summary.correctAnswers < summary.questionsAnswered {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Keep Improving!")
                                .font(.headline)
                            Text("You got \(summary.questionsAnswered - summary.correctAnswers) question\(summary.questionsAnswered - summary.correctAnswers == 1 ? "" : "s") wrong. Review them to master the material.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(PrimaryButtonStyle())
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
