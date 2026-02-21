import SwiftUI

struct ReadinessScoreView: View {
    @ScaledMetric(relativeTo: .title3) private var ringSize = 80
    let score: Double
    let totalQuestions: Int
    let totalCorrect: Int
    let stats: StudyStats?

    var body: some View {
        VStack(spacing: 16) {
            // Readiness ring + label
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: ringSize, height: ringSize)

                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: score)

                    Text("\(Int(score))%")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundColor(scoreColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Exam Readiness")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(readinessMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let stats = stats, stats.answeredAllTime > 0 {
                        Text("\(Int(stats.correctPercentage))% accuracy overall")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            // Quick stats row
            if let stats = stats {
                HStack(spacing: 12) {
                    StatPill(value: "\(stats.answeredToday)", label: "Today")
                    StatPill(value: "\(stats.answeredThisWeek)", label: "This Week")
                    StatPill(value: "\(stats.answeredAllTime)", label: "All Time")
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scoreColor: Color {
        if score >= 75 { return .success }
        if score >= 50 { return .warning }
        if score > 0 { return .error }
        return .secondary
    }
    
    private var readinessMessage: String {
        if score == 0 {
            return "Start studying to build your score"
        } else if score < 50 {
            return "Keep practicing to improve"
        } else if score < 75 {
            return "You're making progress!"
        } else if score < 90 {
            return "Almost exam ready!"
        } else {
            return "You're exam ready! 🎉"
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
