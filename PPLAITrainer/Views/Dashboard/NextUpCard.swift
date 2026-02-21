import SwiftUI

struct NextUpCard: View {
    @Environment(\.dependencies) private var dependencies
    @State private var recommendation: Recommendation?
    @State private var navigationPath = NavigationPath()
    
    enum Recommendation {
        case resumeQuiz(subject: String)
        case reviewSRS(count: Int)
        case focusWeakArea(weakArea: WeakArea)
        case continueStudying(subject: String)
    }
    
    var body: some View {
        Group {
            if let rec = recommendation {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: iconName(for: rec))
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title(for: rec))
                                .font(.headline)
                            Text(subtitle(for: rec))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    NavigationLink(value: rec) {
                        Text(actionText(for: rec))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .cardStyle()
            }
        }
        .navigationDestination(for: Recommendation.self) { rec in
            destinationView(for: rec)
        }
        .task {
            await loadRecommendation()
        }
    }
    
    @ViewBuilder
    private func destinationView(for rec: Recommendation) -> some View {
        guard let deps = dependencies else {
            Text("Error: Dependencies not available")
            return
        }
        
        switch rec {
        case .reviewSRS:
            let vm = deps.makeQuizViewModel()
            QuizSessionView(viewModel: vm)
                .onAppear {
                    vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: true)
                }
        case .focusWeakArea(let weakArea):
            let vm = deps.makeQuizViewModel()
            QuizSessionView(viewModel: vm)
                .onAppear {
                    vm.loadQuestions(categoryId: weakArea.id, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: false)
                }
        case .continueStudying:
            StudyView(viewModel: deps.makeStudyViewModel())
        case .resumeQuiz:
            StudyView(viewModel: deps.makeStudyViewModel())
        }
    }
    
    private func loadRecommendation() async {
        guard let deps = dependencies else { return }
        
        // Priority 1: Check for SRS due cards
        if let dueCards = try? deps.databaseManager.fetchDueCards(limit: nil), !dueCards.isEmpty {
            recommendation = .reviewSRS(count: dueCards.count)
            return
        }
        
        // Priority 2: Check for weak areas (< 60% accuracy, at least 5 attempts)
        if let weakAreas = try? await loadWeakAreas(deps: deps), let weakest = weakAreas.first {
            recommendation = .focusWeakArea(weakArea: weakest)
            return
        }
        
        // Priority 3: Fallback to continue studying
        recommendation = .continueStudying(subject: "Your studies")
    }
    
    @MainActor
    private func loadWeakAreas(deps: Dependencies) async throws -> [WeakArea] {
        let stats = try deps.databaseManager.fetchCategoryStats()
        
        let weakAreas = stats
            .filter { $0.totalAnswered >= 5 && $0.correctPercentage < 0.60 }
            .sorted { $0.correctPercentage < $1.correctPercentage }
            .prefix(3)
            .compactMap { stat -> WeakArea? in
                guard let category = try? deps.databaseManager.fetchCategory(id: stat.categoryId) else { return nil }
                let parentName = category.parent.flatMap { try? deps.databaseManager.fetchCategory(id: $0)?.name } ?? ""
                return WeakArea(
                    id: stat.categoryId,
                    subcategoryName: category.name,
                    parentCategoryName: parentName,
                    correctPercentage: stat.correctPercentage,
                    totalAnswered: stat.totalAnswered
                )
            }
        
        return Array(weakAreas)
    }
    
    private func iconName(for rec: Recommendation) -> String {
        switch rec {
        case .resumeQuiz: return "play.circle.fill"
        case .reviewSRS: return "repeat.circle.fill"
        case .focusWeakArea: return "exclamationmark.triangle.fill"
        case .continueStudying: return "book.circle.fill"
        }
    }
    
    private func title(for rec: Recommendation) -> String {
        switch rec {
        case .resumeQuiz: return "Resume Quiz"
        case .reviewSRS: return "Review Due Cards"
        case .focusWeakArea: return "Focus on Weak Area"
        case .continueStudying: return "Continue Studying"
        }
    }
    
    private func subtitle(for rec: Recommendation) -> String {
        switch rec {
        case .resumeQuiz(let subject): return subject
        case .reviewSRS(let count): return "\(count) card\(count == 1 ? "" : "s") due"
        case .focusWeakArea(let weakArea): return "\(weakArea.subcategoryName) • \(Int(weakArea.correctPercentage * 100))% accuracy"
        case .continueStudying(let subject): return subject
        }
    }
    
    private func actionText(for rec: Recommendation) -> String {
        switch rec {
        case .resumeQuiz: return "Resume"
        case .reviewSRS: return "Start Review"
        case .focusWeakArea: return "Practice Now"
        case .continueStudying: return "Continue"
        }
    }
}
