import GRDB

struct Question: Codable, FetchableRecord, TableRecord {
    var id: Int64
    var category: Int64
    var code: String
    var text: String
    var correct: String
    var incorrect0: String
    var incorrect1: String
    var incorrect2: String
    var explanation: String?
    var reference: String?
    var attachments: String?
    var mockonly: Int64

    static let databaseTableName = "questions"
}

struct Category: Codable, FetchableRecord, TableRecord {
    var id: Int64
    var parent: Int64?
    var quantityinmock: Int64?
    var code: String
    var name: String
    var categorygroup: Int64?
    var sortorder: Int64?
    var locked: String?

    var isTopLevel: Bool { parent == nil || parent == 0 }
    var isLocked: Bool { locked == "1" }
    var mockQuestionCount: Int64 { quantityinmock ?? 0 }

    static let databaseTableName = "categories"
}

struct Attachment: Codable, FetchableRecord, TableRecord {
    var id: Int64
    var name: String
    var filename: String
    var explanation: Int64
    
    static let databaseTableName = "attachments"
}

struct CategoryGroup: Codable, FetchableRecord, TableRecord {
    var id: Int64
    var name: String
    
    static let databaseTableName = "category_groups"
}
