import GRDB
import Foundation

struct Mnemonic: Codable, FetchableRecord, MutablePersistableRecord {
    var questionId: Int64
    var text: String
    var createdAt: Date
    
    static let databaseTableName = "mnemonics"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
