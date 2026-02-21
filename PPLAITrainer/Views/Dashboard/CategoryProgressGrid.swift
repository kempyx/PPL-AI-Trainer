import SwiftUI

struct CategoryProgressGrid: View {
    let categories: [CategoryProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Category Progress", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No progress yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start answering questions to see your progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(categories, id: \.id) { category in
                        NavigationLink(value: category.id) {
                            CategoryProgressRow(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .navigationDestination(for: Int64.self) { categoryId in
            if let category = categories.first(where: { $0.id == categoryId }) {
                CategoryDetailDestination(categoryId: categoryId, categoryName: category.name)
            }
        }
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
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            QuizProgressBar(
                total: category.totalQuestions,
                correct: category.answeredCorrectly,
                incorrect: category.answeredIncorrectly
            )
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

private struct CategoryDetailDestination: View {
    @Environment(\.dependencies) private var deps
    let categoryId: Int64
    let categoryName: String
    
    var body: some View {
        if let deps = deps {
            SubcategoryListView(
                viewModel: StudyViewModel(databaseManager: deps.databaseManager),
                parentId: categoryId,
                parentName: categoryName
            )
        } else {
            Text("Error loading category")
        }
    }
}

#Preview {
    CategoryProgressGrid(categories: [
        CategoryProgress(id: 551, name: "Air Law", percentage: 82, totalQuestions: 120, answeredCorrectly: 98, answeredIncorrectly: 18),
        CategoryProgress(id: 553, name: "Meteorology", percentage: 64, totalQuestions: 95, answeredCorrectly: 61, answeredIncorrectly: 22),
    ])
        .environment(\.dependencies, Dependencies.preview)
}
