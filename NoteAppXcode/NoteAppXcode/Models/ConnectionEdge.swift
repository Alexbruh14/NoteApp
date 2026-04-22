import Foundation
import SwiftData

@Model
class ConnectionEdge {
    @Attribute(.unique) var id: UUID
    var sourceNodeID: String
    var targetNodeID: String
    var relationship: String
    var isVerified: Bool                  // false = dashed line, true = solid line (Phase 6)

    init(sourceNodeID: String, targetNodeID: String, relationship: String) {
        self.id = UUID()
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
        self.relationship = relationship
        self.isVerified = false
    }
}
