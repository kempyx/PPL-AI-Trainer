import Foundation
import GRDB

struct Achievement: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var unlockedAt: Date
    var seen: Bool
    
    static let databaseTableName = "achievements"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .ignore, update: .replace)
}
