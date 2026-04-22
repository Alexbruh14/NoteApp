import SwiftData

@Model
class Note {
    @Attribute(.unique) var id: UUID
    var rawText: String
    var createdAt: Date

    init(rawText: String) {
        self.id = UUID()
        self.rawText = rawText
        self.createdAt = Date()
    }
}
