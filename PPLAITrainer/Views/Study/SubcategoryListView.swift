import SwiftUI

struct SubcategoryListView: View {
    @State var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    let parentId: Int64
    let parentName: String
    
    @State private var showQuizPicker = false
    @State private var pendingQuizCount: Int?

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
                                    .onAppear {
                                        deps.settingsManager.setLastStudiedSubject(id: parentId, name: parentName)
                                    }
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
        .sheet(isPresented: $showQuizPicker) {
            if deps != nil {
                QuizPickerSheet(
                    subjectName: parentName,
                    totalQuestions: totalQuestionCount
                ) { count in
                    pendingQuizCount = count
                }
            }
        }
        .navigationDestination(item: $pendingQuizCount) { count in
            if let deps = deps {
                QuizSessionView(viewModel: makeQuizVM(deps, parentCategoryId: parentId, limit: count))
                    .onAppear {
                        deps.settingsManager.setLastStudiedSubject(id: parentId, name: parentName)
                    }
            }
        }
    }

    private func studyAllButton(_ deps: Dependencies) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                NavigationLink {
                    QuizSessionView(viewModel: makeQuizVM(deps, parentCategoryId: parentId, limit: 10))
                        .onAppear {
                            deps.settingsManager.setLastStudiedSubject(id: parentId, name: parentName)
                        }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                        Text("Quick")
                            .font(.caption.weight(.semibold))
                        Text("10 q")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .buttonStyle(.plain)
                
                Button {
                    showQuizPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                        Text("Custom")
                            .font(.caption.weight(.semibold))
                        Text("Choose")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                showQuizPicker = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.subheadline)
                    Text("Study All Questions")
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
            
            NavigationLink {
                FlashcardView(sessionType: .quickReview)
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                        .font(.subheadline)
                    Text("Flashcards")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var totalQuestionCount: Int {
        viewModel.subcategories.reduce(0) { $0 + $1.stats.totalQuestions }
    }

    private func makeQuizVM(_ deps: Dependencies, categoryId: Int64? = nil, parentCategoryId: Int64? = nil, limit: Int? = nil) -> QuizViewModel {
        let vm = deps.quizCoordinator.makeViewModel(mode: .category(categoryId: categoryId, parentCategoryId: parentCategoryId))
        if let limit = limit, let parentCategoryId = parentCategoryId {
            // Load limited questions from parent category
            Task { @MainActor in
                do {
                    let allQuestions = try deps.databaseManager.fetchQuestions(parentCategoryId: parentCategoryId, excludeMockOnly: true)
                    let limitedQuestions = Array(allQuestions.shuffled().prefix(limit))
                    vm.loadQuestions(from: limitedQuestions)
                } catch {
                        }
            }
        } else {
        }
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
                
                // Status badges
                HStack(spacing: 4) {
                    if isMastered {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    if hasDueReview {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 8))
                    }
                    if hasWrongAnswers {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 8))
                    }
                }

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
    
    private var isMastered: Bool {
        guard item.stats.totalQuestions > 0 else { return false }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions) * 100
        return pct >= 90
    }
    
    private var hasDueReview: Bool {
        // Simplified - would need SRS data
        return false
    }
    
    private var hasWrongAnswers: Bool {
        return item.stats.answeredQuestions > item.stats.correctAnswers
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

#Preview {
    @Previewable @State var viewModel = StudyViewModel(databaseManager: MockDatabaseManager())
    SubcategoryListView(
        viewModel: viewModel,
        parentId: 1,
        parentName: "Sample Category"
    )
    .environment(\.dependencies, Dependencies.preview)
}
