import GRDB
import Foundation

struct AnswerRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var questionId: Int64
    var chosenAnswer: String
    var isCorrect: Bool
    var timestamp: Date
    
    static let databaseTableName = "answer_records"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
