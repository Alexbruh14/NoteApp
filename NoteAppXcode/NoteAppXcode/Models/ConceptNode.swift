import SwiftData

@Model
class ConceptNode {
    @Attribute(.unique) var id: String   // matches the "id" field from the Python JSON
    var label: String
    var type: String                      // Person | Concept | Book | Event | Place
    var positionX: Double
    var positionY: Double

    init(id: String, label: String, type: String) {
        self.id = id
        self.label = label
        self.type = type
        self.positionX = Double.random(in: 100...700)
        self.positionY = Double.random(in: 100...500)
    }
}
