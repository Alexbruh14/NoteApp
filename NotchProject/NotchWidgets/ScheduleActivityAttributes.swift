import ActivityKit
import Foundation

struct ScheduleActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var eventTitle: String
        var presetIcon: String
        var colorHex: String
        var endTime: Date
        var notes: String
        var linkTitles: [String]
        var linkURLs: [String]
        var enableDND: Bool
    }

    var eventID: String
    var startTime: Date
}
