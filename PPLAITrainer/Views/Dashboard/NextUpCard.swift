import SwiftUI

struct NextUpCard: View {
    @Environment(\.dependencies) private var dependencies
    @State private var recommendation: Recommendation?
    @State private var studyViewModel: StudyViewModel

    init(studyViewModel: StudyViewModel) {
        self.studyViewModel = studyViewModel
    }
    
    enum Recommendation {
        case reviewSRS(count: Int)
        case reviewWrongAnswers(count: Int)
        case dailyGoalBoost(remaining: Int)
        case weakAreaDrill(count: Int)
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
                    
                    NavigationLink {
                        destinationView(for: rec)
                    } label: {
                        Text(actionText(for: rec))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .cardStyle()
            }
        }
        .task {
            await loadRecommendation()
        }
    }
    
    @ViewBuilder
    private func destinationView(for rec: Recommendation) -> some View {
        if let deps = dependencies {
            switch rec {
            case .reviewSRS:
                QuizSessionView(viewModel: deps.quizCoordinator.makeViewModel(mode: .srsDue))
            case .reviewWrongAnswers:
                QuizSessionView(viewModel: deps.quizCoordinator.makeViewModel(mode: .wrongAnswers))
            case .dailyGoalBoost, .weakAreaDrill:
                let engine = SmartSessionEngine(databaseManager: deps.databaseManager)
                let leg = deps.settingsManager.activeLeg
                if let questions = try? engine.generateSession(type: .weakAreaFocus, leg: leg), !questions.isEmpty {
                    QuizSessionView(viewModel: deps.quizCoordinator.makeViewModel(mode: .preloaded(questions)))
                } else {
                    StudyView(viewModel: studyViewModel)
                }
            case .continueStudying:
                StudyView(viewModel: studyViewModel)
            }
        } else {
            Text("Dependencies unavailable")
        }
    }
    
    private func loadRecommendation() async {
        guard let deps = dependencies else { return }
        if let dueCards = try? deps.databaseManager.fetchDueCards(limit: nil), !dueCards.isEmpty {
            setRecommendation(.reviewSRS(count: dueCards.count), deps: deps)
            return
        }
        if let wrongCount = try? deps.databaseManager.fetchWrongAnswerQuestionIds().count, wrongCount > 0 {
            setRecommendation(.reviewWrongAnswers(count: wrongCount), deps: deps)
            return
        }
        let target = deps.settingsManager.dailyGoalTarget
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        if let day = try? deps.databaseManager.fetchStudyDays(from: today, to: today).first,
           target > day.questionsAnswered {
            setRecommendation(.dailyGoalBoost(remaining: target - day.questionsAnswered), deps: deps)
            return
        } else if target > 0 {
            setRecommendation(.dailyGoalBoost(remaining: target), deps: deps)
            return
        }
        setRecommendation(.weakAreaDrill(count: 15), deps: deps)
    }

    private func setRecommendation(_ rec: Recommendation, deps: Dependencies) {
        recommendation = rec
        try? deps.databaseManager.logInteractionEvent(
            name: "dashboard_nextup_recommendation",
            questionId: nil,
            metadata: "type=\(title(for: rec))"
        )
    }
    
    private func iconName(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "repeat.circle.fill"
        case .reviewWrongAnswers: return "xmark.circle.fill"
        case .dailyGoalBoost: return "target"
        case .weakAreaDrill: return "scope"
        case .continueStudying: return "book.circle.fill"
        }
    }
    
    private func title(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "Review Due Cards"
        case .reviewWrongAnswers: return "Fix Recent Mistakes"
        case .dailyGoalBoost: return "Finish Daily Goal"
        case .weakAreaDrill: return "Weak-Area Drill"
        case .continueStudying: return "Continue Studying"
        }
    }
    
    private func subtitle(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS(let count): return "\(count) card\(count == 1 ? "" : "s") due"
        case .reviewWrongAnswers(let count): return "\(count) question\(count == 1 ? "" : "s") still marked wrong"
        case .dailyGoalBoost(let remaining): return "\(remaining) more question\(remaining == 1 ? "" : "s") to hit today's target"
        case .weakAreaDrill(let count): return "\(count)-question targeted session based on your weakest topics"
        case .continueStudying(let subject): return subject
        }
    }
    
    private func actionText(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "Start Review"
        case .reviewWrongAnswers: return "Review Mistakes"
        case .dailyGoalBoost: return "Complete Goal"
        case .weakAreaDrill: return "Start Drill"
        case .continueStudying: return "Continue"
        }
    }
}

#Preview {
    NextUpCard(studyViewModel: StudyViewModel(databaseManager: Dependencies.preview.databaseManager))
        .environment(\.dependencies, Dependencies.preview)
}
