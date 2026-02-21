import SwiftUI

struct NextUpCard: View {
    @Environment(\.dependencies) private var dependencies
    @State private var recommendation: Recommendation?
    
    enum Recommendation {
        case resumeQuiz(subject: String)
        case reviewSRS(count: Int)
        case focusWeakArea(subject: String, accuracy: Double)
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
                    
                    Button(action: {}) {
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
    
    private func loadRecommendation() async {
        guard let deps = dependencies else { return }
        
        // Priority 1: Check for SRS due cards
        if let dueCards = try? deps.databaseManager.fetchDueCards(limit: nil), !dueCards.isEmpty {
            recommendation = .reviewSRS(count: dueCards.count)
            return
        }
        
        // Priority 2: Fallback to continue studying
        recommendation = .continueStudying(subject: "Your studies")
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
        case .focusWeakArea(let subject, let accuracy): return "\(subject) • \(Int(accuracy * 100))% accuracy"
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
