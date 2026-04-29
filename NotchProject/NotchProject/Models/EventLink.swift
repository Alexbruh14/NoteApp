import Foundation
import SwiftData

enum LinkType: String, Codable, CaseIterable {
    case pdf
    case webpage
    case other
}

@Model
final class EventLink {
    var id: UUID
    var title: String
    var urlString: String
    var type: LinkType

    @Relationship(inverse: \ScheduleEvent.links)
    var event: ScheduleEvent?

    init(title: String, urlString: String, type: LinkType = .webpage) {
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.type = type
    }

    var url: URL? {
        URL(string: urlString)
    }
}
