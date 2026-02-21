import Foundation

struct PresentedQuestion {
    let question: Question
    let shuffledAnswers: [String]
    let correctAnswerIndex: Int
    let questionAttachments: [Attachment]
    let explanationAttachments: [Attachment]
    let categoryName: String
}

struct CategoryStat {
    let categoryId: Int64
    let categoryName: String
    let totalQuestions: Int
    let answeredQuestions: Int
    let correctAnswers: Int
}

struct CategoryWithStats {
    let category: Category
    let stats: CategoryStat
    let srsStats: SRSStats
    var subcategoryCount: Int = 0
}

enum SRSMaturity {
    case new
    case learning
    case review
    case mastered
}

struct SRSStats {
    let newCount: Int
    let learningCount: Int
    let reviewCount: Int
    let masteredCount: Int
}

struct StudyStats {
    let answeredToday: Int
    let answeredThisWeek: Int
    let answeredAllTime: Int
    let correctPercentage: Double
}

struct CategoryProgress {
    let id: Int64
    let name: String
    let percentage: Double
    let totalQuestions: Int
    let answeredCorrectly: Int
    let answeredIncorrectly: Int
}

struct WeakArea {
    let id: Int64
    let subcategoryName: String
    let parentCategoryName: String
    let correctPercentage: Double
    let totalAnswered: Int
}

struct DisplayCategory: Identifiable {
    let id: String
    let name: String
    let memberCategories: [CategoryWithStats]
    let stats: CategoryStat
    let srsStats: SRSStats
    let subcategoryCount: Int

    var isGroup: Bool { memberCategories.count > 1 }
    var primaryCategoryId: Int64 { memberCategories.first?.category.id ?? 0 }
}

struct MockExamScore: Equatable {
    let totalQuestions: Int
    let correctAnswers: Int
    let percentage: Double
    let passed: Bool
    let subjectBreakdown: [SubjectExamScore]
}

struct SubjectExamScore: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let totalQuestions: Int
    let correctAnswers: Int
    var percentage: Double { totalQuestions == 0 ? 0 : Double(correctAnswers) / Double(totalQuestions) * 100 }
    var passed: Bool { percentage >= 75.0 }
    
    enum CodingKeys: String, CodingKey {
        case name, totalQuestions, correctAnswers
    }
}

// MARK: - PresentedQuestion Factory

extension PresentedQuestion {
    static func from(_ question: Question, databaseManager: DatabaseManaging) throws -> PresentedQuestion {
        let answers = [question.correct, question.incorrect0, question.incorrect1, question.incorrect2].shuffled()
        let correctIndex = answers.firstIndex(of: question.correct) ?? 0
        let attachmentIds = question.attachments?.split(separator: ",").compactMap { Int64($0.trimmingCharacters(in: .whitespaces)) } ?? []
        let allAttachments = try databaseManager.fetchAttachments(ids: attachmentIds)
        let category = try databaseManager.fetchCategoryStats(categoryId: question.category)
        return PresentedQuestion(
            question: question,
            shuffledAnswers: answers,
            correctAnswerIndex: correctIndex,
            questionAttachments: allAttachments.filter { $0.explanation == 0 },
            explanationAttachments: allAttachments.filter { $0.explanation == 1 },
            categoryName: category.categoryName
        )
    }
}
