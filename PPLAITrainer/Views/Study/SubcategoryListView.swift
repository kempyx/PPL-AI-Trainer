import SwiftUI

struct SubcategoryListView: View {
    @State var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    let parentId: Int64
    let parentName: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let deps = deps {
                    studyAllButton(deps)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }

                LazyVStack(spacing: 1) {
                    ForEach(viewModel.subcategories, id: \.category.id) { item in
                        if let deps = deps {
                            NavigationLink {
                                QuizSessionView(viewModel: makeQuizVM(deps, categoryId: item.category.id))
                            } label: {
                                SubcategoryRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle(parentName)
        .onAppear {
            viewModel.loadSubcategories(parentId: parentId)
        }
    }

    private func studyAllButton(_ deps: Dependencies) -> some View {
        NavigationLink {
            QuizSessionView(viewModel: makeQuizVM(deps, parentCategoryId: parentId))
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                Text("Study All")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(totalQuestionCount) questions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var totalQuestionCount: Int {
        viewModel.subcategories.reduce(0) { $0 + $1.stats.totalQuestions }
    }

    private func makeQuizVM(_ deps: Dependencies, categoryId: Int64? = nil, parentCategoryId: Int64? = nil) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        vm.loadQuestions(categoryId: categoryId, parentCategoryId: parentCategoryId, wrongAnswersOnly: false, srsDueOnly: false)
        return vm
    }
}

private struct SubcategoryRow: View {
    let item: CategoryWithStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.category.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                if item.stats.answeredQuestions > 0 {
                    Text(progressPercentage)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundColor(progressColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("\(item.stats.totalQuestions)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            QuizProgressBar(
                total: item.stats.totalQuestions,
                correct: item.stats.correctAnswers,
                incorrect: item.stats.answeredQuestions - item.stats.correctAnswers
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var progressPercentage: String {
        guard item.stats.totalQuestions > 0 else { return "" }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions) * 100
        return "\(Int(pct))%"
    }

    private var progressColor: Color {
        guard item.stats.totalQuestions > 0, item.stats.answeredQuestions > 0 else { return .secondary }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions)
        if pct >= 0.75 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }
}
