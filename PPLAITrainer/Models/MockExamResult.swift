import GRDB
import Foundation

struct CategoryExamScore: Codable, Equatable {
    var categoryId: Int64
    var categoryName: String
    var totalQuestions: Int
    var correctAnswers: Int
}

struct MockExamResult: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var startedAt: Date
    var completedAt: Date
    var totalQuestions: Int
    var correctAnswers: Int
    var percentage: Double
    var passed: Bool
    var categoryBreakdown: Data
    var leg: Int
    
    static let databaseTableName = "mock_exam_results"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
