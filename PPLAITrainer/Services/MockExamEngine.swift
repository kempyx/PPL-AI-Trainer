import Foundation
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "MockExamEngine")

enum ExamLeg: Int, CaseIterable, Identifiable, Hashable {
    case technicalLegal = 1
    case humanEnvironment = 2
    case planningNavigation = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .technicalLegal: return "Leg 1: Technical & Legal"
        case .humanEnvironment: return "Leg 2: Human & Environment"
        case .planningNavigation: return "Leg 3: Planning & Navigation"
        }
    }
    
    var subtitle: String {
        switch self {
        case .technicalLegal: return "AGK, Instrumentation, Principles of Flight, Air Law"
        case .humanEnvironment: return "Meteorology, Human Performance, Communications"
        case .planningNavigation: return "Navigation, Flight Planning, Performance, Ops"
        }
    }
    
    /// Parent category IDs for each leg, with question quotas per category
    var categoryQuotas: [(parentCategoryId: Int64, questionCount: Int)] {
        switch self {
        case .technicalLegal:
            return [
                (560, 12), // AGK + Systems
                (528, 8),  // Instrumentation
                (555, 12), // Principles of Flight
                (551, 12)  // Air Law
            ]
        case .humanEnvironment:
            return [
                (553, 16), // Meteorology
                (552, 12), // Human Performance
                (554, 12)  // Communications
            ]
        case .planningNavigation:
            return [
                (501, 12), // General Navigation
                (500, 8),  // Radio Navigation
                (557, 6),  // Mass and Balance
                (558, 6),  // Performance
                (559, 6),  // Flight Planning
                (556, 6)   // Operational Procedures
            ]
        }
    }
    
    var totalQuestions: Int {
        categoryQuotas.reduce(0) { $0 + $1.questionCount }
    }
    
    var timeLimitMinutes: Int {
        // 75 seconds per question, rounded to nearest 5 min
        let raw = Double(totalQuestions * 75) / 60.0
        return Int((raw / 5.0).rounded(.up)) * 5
    }
}

final class MockExamEngine {
    private let databaseManager: DatabaseManaging
    
    init(databaseManager: DatabaseManaging) {
        self.databaseManager = databaseManager
    }
    
    func generateExam(leg: ExamLeg) throws -> [Question] {
        var questions: [Question] = []
        
        for quota in leg.categoryQuotas {
            let subcategories = try databaseManager.fetchSubcategories(parentId: quota.parentCategoryId)
            let subcategoryIds = subcategories.map(\.id)
            
            logger.info("Leg \(leg.rawValue) - category \(quota.parentCategoryId): \(subcategories.count) subcategories, need \(quota.questionCount) questions")
            
            if subcategoryIds.isEmpty {
                // Fallback: query directly on parent category
                let fetched = try databaseManager.fetchRandomQuestions(categoryId: quota.parentCategoryId, limit: quota.questionCount, mockOnlyAllowed: true)
                logger.info("  Fetched \(fetched.count) from parent directly")
                questions.append(contentsOf: fetched)
            } else {
                // Pull from subcategories
                let fetched = try databaseManager.fetchRandomQuestionsFromCategories(categoryIds: subcategoryIds, limit: quota.questionCount)
                logger.info("  Fetched \(fetched.count) from subcategories")
                questions.append(contentsOf: fetched)
            }
        }
        
        logger.info("Generated exam for \(leg.title): \(questions.count) questions")
        return questions.shuffled()
    }
    
    func timeLimit(leg: ExamLeg) -> TimeInterval {
        TimeInterval(leg.timeLimitMinutes * 60)
    }
    
    func scoreExam(questions: [Question], answers: [Int64: String]) throws -> MockExamScore {
        var correctCount = 0
        var categoryBreakdown: [Int64: (name: String, total: Int, correct: Int)] = [:]
        
        for question in questions {
            let isCorrect = answers[question.id] == question.correct
            if isCorrect { correctCount += 1 }
            
            let categoryId = question.category
            let categoryName = (try? databaseManager.fetchCategoryStats(categoryId: categoryId))?.categoryName ?? "Unknown"
            
            if var stats = categoryBreakdown[categoryId] {
                stats.total += 1
                if isCorrect { stats.correct += 1 }
                categoryBreakdown[categoryId] = stats
            } else {
                categoryBreakdown[categoryId] = (categoryName, 1, isCorrect ? 1 : 0)
            }
        }
        
        let percentage = questions.isEmpty ? 0.0 : Double(correctCount) / Double(questions.count) * 100
        let passed = percentage >= 75.0
        
        let breakdown = categoryBreakdown.map {
            CategoryExamScore(categoryId: $0.key, categoryName: $0.value.name, totalQuestions: $0.value.total, correctAnswers: $0.value.correct)
        }.sorted { $0.categoryName < $1.categoryName }
        
        return MockExamScore(totalQuestions: questions.count, correctAnswers: correctCount, percentage: percentage, passed: passed, categoryBreakdown: breakdown)
    }
}
