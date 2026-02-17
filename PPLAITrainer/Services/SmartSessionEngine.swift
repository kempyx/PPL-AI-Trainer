import Foundation

enum SessionType {
    case quickReview
    case dailyPractice
    case weakAreaFocus
    case preExamDrill
    case subjectFocus(parentCategoryId: Int64)
    case legFocus(leg: ExamLeg)
    
    var title: String {
        switch self {
        case .quickReview: return "Quick Review"
        case .dailyPractice: return "Daily Practice"
        case .weakAreaFocus: return "Weak Area Focus"
        case .preExamDrill: return "Pre-Exam Drill"
        case .subjectFocus: return "Subject Focus"
        case .legFocus(let leg): return leg.title
        }
    }
    
    var icon: String {
        switch self {
        case .quickReview: return "bolt.fill"
        case .dailyPractice: return "calendar"
        case .weakAreaFocus: return "target"
        case .preExamDrill: return "airplane"
        case .subjectFocus: return "book.fill"
        case .legFocus: return "list.number"
        }
    }
    
    var description: String {
        switch self {
        case .quickReview: return "10 quick questions"
        case .dailyPractice: return "20 mixed questions"
        case .weakAreaFocus: return "15 from weak areas"
        case .preExamDrill: return "Full exam simulation"
        case .subjectFocus: return "20 from one subject"
        case .legFocus: return "30 across leg subjects"
        }
    }
    
    var questionCount: Int {
        switch self {
        case .quickReview: return 10
        case .dailyPractice: return 20
        case .weakAreaFocus: return 15
        case .preExamDrill: return 60
        case .subjectFocus: return 20
        case .legFocus: return 30
        }
    }
}

struct SmartSessionEngine {
    private let databaseManager: DatabaseManaging
    
    init(databaseManager: DatabaseManaging) {
        self.databaseManager = databaseManager
    }
    
    /// Generate a session scoped to a specific leg
    func generateSession(type: SessionType, leg: ExamLeg) throws -> [Question] {
        switch type {
        case .weakAreaFocus:
            return try weakAreaQuestions(leg: leg, limit: type.questionCount)
        case .subjectFocus(let parentId):
            return try subjectQuestions(parentCategoryId: parentId, limit: type.questionCount)
        case .legFocus(let leg):
            return try legQuestions(leg: leg, limit: type.questionCount)
        case .preExamDrill:
            return try legQuestions(leg: leg, limit: leg.totalQuestions)
        default:
            return try legQuestions(leg: leg, limit: type.questionCount)
        }
    }
    
    private func subcategoryIds(for leg: ExamLeg) throws -> [Int64] {
        var ids: [Int64] = []
        for parentId in leg.parentCategoryIds {
            let subs = try databaseManager.fetchSubcategories(parentId: parentId)
            ids.append(contentsOf: subs.map(\.id))
        }
        return ids
    }
    
    private func legQuestions(leg: ExamLeg, limit: Int) throws -> [Question] {
        let ids = try subcategoryIds(for: leg)
        guard !ids.isEmpty else { return [] }
        return try databaseManager.fetchRandomQuestionsFromCategories(categoryIds: ids, limit: limit)
    }
    
    private func weakAreaQuestions(leg: ExamLeg, limit: Int) throws -> [Question] {
        var scored: [(id: Int64, pct: Double)] = []
        for parentId in leg.parentCategoryIds {
            let subs = try databaseManager.fetchSubcategories(parentId: parentId)
            for sub in subs {
                let stats = try databaseManager.fetchCategoryStats(categoryId: sub.id)
                if stats.answeredQuestions > 0 {
                    scored.append((sub.id, Double(stats.correctAnswers) / Double(stats.answeredQuestions)))
                }
            }
        }
        let weakIds = scored.sorted { $0.pct < $1.pct }.prefix(5).map(\.id)
        if weakIds.isEmpty { return [] }
        return try databaseManager.fetchRandomQuestionsFromCategories(categoryIds: weakIds, limit: limit)
    }
    
    private func subjectQuestions(parentCategoryId: Int64, limit: Int) throws -> [Question] {
        let subs = try databaseManager.fetchSubcategories(parentId: parentCategoryId)
        guard !subs.isEmpty else { return [] }
        return try databaseManager.fetchRandomQuestionsFromCategories(categoryIds: subs.map(\.id), limit: limit)
    }
}
