import Foundation

struct SessionSummary {
    let questionsAnswered: Int
    let correctAnswers: Int
    let accuracy: Double
    let xpEarned: Int
    let xpBreakdown: [(label: String, amount: Int)]
    let currentStreak: Int
    let categoryDeltas: [(categoryName: String, delta: String)]
    let suggestedAction: SuggestedAction
}

enum SuggestedAction {
    case reviewSRSCards(count: Int)
    case studyWeakArea(name: String, categoryId: Int64)
    case takeBreak
    case continuePractice(remaining: Int)
}
