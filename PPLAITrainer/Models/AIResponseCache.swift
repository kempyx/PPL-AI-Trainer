import GRDB
import Foundation

struct AIResponseCache: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var questionId: Int64
    var responseType: String // "hint", "explain", "simplify", "analogy", "mistakes"
    var response: String
    var createdAt: Date
    
    static let databaseTableName = "ai_response_cache"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
