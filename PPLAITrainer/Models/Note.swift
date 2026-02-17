import Foundation
import GRDB

struct Note: Codable, FetchableRecord, MutablePersistableRecord {
    var questionId: Int64
    var text: String
    var updatedAt: Date
    
    static let databaseTableName = "notes"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
