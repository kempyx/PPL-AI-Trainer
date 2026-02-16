import GRDB
import Foundation

struct SRSCard: Codable, FetchableRecord, MutablePersistableRecord {
    var questionId: Int64
    var box: Int
    var easeFactor: Double
    var interval: Int
    var repetitions: Int
    var nextReviewDate: Date
    
    static let databaseTableName = "srs_cards"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
