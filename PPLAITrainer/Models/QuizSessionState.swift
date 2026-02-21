import GRDB
import Foundation

struct QuizSessionState: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var categoryId: Int64?
    var categoryName: String?
    var currentIndex: Int
    var questionIds: String // Comma-separated question IDs
    var answers: String // JSON array of selected answers (nullable ints)
    var timestamp: Date
    
    static let databaseTableName = "quiz_sessions"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
