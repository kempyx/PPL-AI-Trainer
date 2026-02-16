import GRDB
import Foundation

struct StudyDay: Codable, FetchableRecord, MutablePersistableRecord {
    var date: String
    var questionsAnswered: Int
    var correctAnswers: Int
    
    static let databaseTableName = "study_days"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
