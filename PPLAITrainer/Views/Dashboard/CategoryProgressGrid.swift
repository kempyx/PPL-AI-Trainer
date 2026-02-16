import SwiftUI

struct CategoryProgressGrid: View {
    let categories: [CategoryProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Category Progress", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            VStack(spacing: 10) {
                ForEach(categories, id: \.id) { category in
                    CategoryProgressRow(category: category)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CategoryProgressRow: View {
    let category: CategoryProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(category.answeredCorrectly)/\(category.totalQuestions)")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)

                Text(percentageText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(progressColor)
                    .frame(width: 36, alignment: .trailing)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let filled = category.totalQuestions > 0
                    ? width * CGFloat(category.answeredCorrectly) / CGFloat(category.totalQuestions)
                    : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    if filled > 0 {
                        Capsule()
                            .fill(progressColor)
                            .frame(width: max(filled, 3), height: 6)
                    }
                }
            }
            .frame(height: 6)
        }
    }

    private var percentageText: String {
        guard category.totalQuestions > 0 else { return "—" }
        return "\(Int(category.percentage))%"
    }

    private var progressColor: Color {
        guard category.totalQuestions > 0, category.answeredCorrectly > 0 else { return .secondary }
        if category.percentage >= 75 { return .green }
        if category.percentage >= 50 { return .orange }
        return .red
    }
}
