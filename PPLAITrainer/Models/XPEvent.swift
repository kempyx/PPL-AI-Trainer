import Foundation
import GRDB

struct XPEvent: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var amount: Int
    var source: String
    var timestamp: Date
    
    static let databaseTableName = "xp_events"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
