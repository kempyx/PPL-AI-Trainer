import SwiftUI

struct StreakCalendarView: View {
    let studyDays: [StudyDay]
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Study Streak", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("\(currentStreak)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundColor(currentStreak > 0 ? .orange : .secondary)
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 0) {
                        Text("\(longestStreak)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("Best")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Heat map grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(last30Days(), id: \.self) { date in
                    let intensity = intensityForDate(date)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(colorForIntensity(intensity))
                        .frame(height: 24)
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(colorForIntensity(i))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func last30Days() -> [String] {
        let formatter = DateFormatter.yyyyMMdd

        return (0..<28).map { offset in
            formatter.string(from: Calendar.current.date(byAdding: .day, value: -offset, to: Date())!)
        }.reversed()
    }

    private func intensityForDate(_ date: String) -> Int {
        guard let day = studyDays.first(where: { $0.date == date }) else { return 0 }
        if day.questionsAnswered >= 20 { return 3 }
        if day.questionsAnswered >= 10 { return 2 }
        if day.questionsAnswered > 0 { return 1 }
        return 0
    }

    private func colorForIntensity(_ intensity: Int) -> Color {
        switch intensity {
        case 3: return .green
        case 2: return .green.opacity(0.6)
        case 1: return .green.opacity(0.3)
        default: return Color(.systemGray5)
        }
    }
}
