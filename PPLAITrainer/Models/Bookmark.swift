import Foundation
import GRDB

struct Bookmark: Codable, FetchableRecord, MutablePersistableRecord {
    var questionId: Int64
    var createdAt: Date
    
    static let databaseTableName = "bookmarks"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
