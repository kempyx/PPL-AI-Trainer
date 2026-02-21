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
            recommendation = .reviewSRS(count: dueCards.count)
            return
        }
        recommendation = .continueStudying(subject: "Your studies")
    }
    
    private func iconName(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "repeat.circle.fill"
        case .continueStudying: return "book.circle.fill"
        }
    }
    
    private func title(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "Review Due Cards"
        case .continueStudying: return "Continue Studying"
        }
    }
    
    private func subtitle(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS(let count): return "\(count) card\(count == 1 ? "" : "s") due"
        case .continueStudying(let subject): return subject
        }
    }
    
    private func actionText(for rec: Recommendation) -> String {
        switch rec {
        case .reviewSRS: return "Start Review"
        case .continueStudying: return "Continue"
        }
    }
}

#Preview {
    NextUpCard(studyViewModel: StudyViewModel(databaseManager: Dependencies.preview.databaseManager))
        .environment(\.dependencies, Dependencies.preview)
}
