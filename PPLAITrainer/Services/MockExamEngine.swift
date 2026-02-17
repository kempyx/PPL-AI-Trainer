import Foundation
import SwiftUI
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
    
    var shortTitle: String {
        switch self {
        case .technicalLegal: return "Leg 1"
        case .humanEnvironment: return "Leg 2"
        case .planningNavigation: return "Leg 3"
        }
    }
    
    var emoji: String {
        switch self {
        case .technicalLegal: return "✈️"
        case .humanEnvironment: return "🧠"
        case .planningNavigation: return "🗺️"
        }
    }
    
    var color: Color {
        switch self {
        case .technicalLegal: return .blue
        case .humanEnvironment: return .teal
        case .planningNavigation: return .orange
        }
    }
    
    var subtitle: String {
        switch self {
        case .technicalLegal: return "AGK, Principles of Flight, Air Law"
        case .humanEnvironment: return "Meteorology, Human Performance, Communications"
        case .planningNavigation: return "Navigation, Flight Performance & Planning, Ops"
        }
    }
    
    /// Subjects per leg matching PEXO exam structure: 20 questions per subject, 60 per leg
    /// Each subject may span multiple DB parent categories
    var subjectQuotas: [(name: String, parentCategoryIds: [Int64], questionCount: Int, timeMinutes: Int)] {
        switch self {
        case .technicalLegal:
            return [
                ("Aircraft General Knowledge", [560, 528], 20, 35),
                ("Principles of Flight", [555], 20, 45),
                ("Air Law", [551], 20, 45),
            ]
        case .humanEnvironment:
            return [
                ("Meteorology", [553], 20, 45),
                ("Human Performance", [552], 20, 30),
                ("Communications", [554], 20, 30),
            ]
        case .planningNavigation:
            return [
                ("Navigation", [501, 500], 20, 65),
                ("Flight Performance & Planning", [557, 558, 559], 20, 95),
                ("Operational Procedures", [556], 20, 30),
            ]
        }
    }
    
    /// Flattened quotas for backward compatibility with exam generation
    var categoryQuotas: [(parentCategoryId: Int64, questionCount: Int)] {
        subjectQuotas.flatMap { subject in
            let perCategory = subject.questionCount / subject.parentCategoryIds.count
            let remainder = subject.questionCount % subject.parentCategoryIds.count
            return subject.parentCategoryIds.enumerated().map { i, catId in
                (catId, perCategory + (i < remainder ? 1 : 0))
            }
        }
    }
    
    var totalQuestions: Int { 60 }
    
    var parentCategoryIds: [Int64] {
        subjectQuotas.flatMap(\.parentCategoryIds)
    }
    
    var timeLimitMinutes: Int {
        subjectQuotas.reduce(0) { $0 + $1.timeMinutes }
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
    
    func scoreExam(questions: [Question], answers: [Int64: String], leg: ExamLeg) throws -> MockExamScore {
        // Build lookup: parentCategoryId -> subject name
        var categoryToSubject: [Int64: String] = [:]
        for subject in leg.subjectQuotas {
            for catId in subject.parentCategoryIds {
                categoryToSubject[catId] = subject.name
                // Also map subcategories
                let subs = try databaseManager.fetchSubcategories(parentId: catId)
                for sub in subs {
                    categoryToSubject[sub.id] = subject.name
                }
            }
        }
        
        var subjectStats: [String: (total: Int, correct: Int)] = [:]
        var correctCount = 0
        
        for question in questions {
            let isCorrect = answers[question.id] == question.correct
            if isCorrect { correctCount += 1 }
            
            let subjectName = categoryToSubject[question.category] ?? "Unknown"
            var stats = subjectStats[subjectName, default: (0, 0)]
            stats.total += 1
            if isCorrect { stats.correct += 1 }
            subjectStats[subjectName] = stats
        }
        
        let percentage = questions.isEmpty ? 0.0 : Double(correctCount) / Double(questions.count) * 100
        let breakdown = subjectStats.map {
            SubjectExamScore(name: $0.key, totalQuestions: $0.value.total, correctAnswers: $0.value.correct)
        }.sorted { $0.name < $1.name }
        
        let passed = breakdown.allSatisfy(\.passed)
        
        return MockExamScore(totalQuestions: questions.count, correctAnswers: correctCount, percentage: percentage, passed: passed, subjectBreakdown: breakdown)
    }
}
