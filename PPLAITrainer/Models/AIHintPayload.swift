import Foundation

struct AIHintPayload: Codable {
    struct ImageReference: Codable, Identifiable {
        var id: String
        var path: String
        var mimeType: String

        init(id: String = UUID().uuidString, path: String, mimeType: String) {
            self.id = id
            self.path = path
            self.mimeType = mimeType
        }
    }

    var text: String
    var images: [ImageReference]
    var provider: String
    var model: String
    var createdAt: Date
}
