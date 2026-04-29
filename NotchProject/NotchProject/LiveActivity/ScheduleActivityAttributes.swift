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

        var compactLeadingStyle: String
        var minimalStyle: String
        var expandedShowIcon: Bool
        var expandedShowTimer: Bool
        var expandedShowNotes: Bool
        var expandedShowLinks: Bool

        init(
            eventTitle: String, presetIcon: String, colorHex: String, endTime: Date,
            notes: String, linkTitles: [String], linkURLs: [String], enableDND: Bool,
            compactLeadingStyle: String = "capsule", minimalStyle: String = "dot",
            expandedShowIcon: Bool = true, expandedShowTimer: Bool = true,
            expandedShowNotes: Bool = true, expandedShowLinks: Bool = true
        ) {
            self.eventTitle = eventTitle
            self.presetIcon = presetIcon
            self.colorHex = colorHex
            self.endTime = endTime
            self.notes = notes
            self.linkTitles = linkTitles
            self.linkURLs = linkURLs
            self.enableDND = enableDND
            self.compactLeadingStyle = compactLeadingStyle
            self.minimalStyle = minimalStyle
            self.expandedShowIcon = expandedShowIcon
            self.expandedShowTimer = expandedShowTimer
            self.expandedShowNotes = expandedShowNotes
            self.expandedShowLinks = expandedShowLinks
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            eventTitle = try container.decode(String.self, forKey: .eventTitle)
            presetIcon = try container.decode(String.self, forKey: .presetIcon)
            colorHex = try container.decode(String.self, forKey: .colorHex)
            endTime = try container.decode(Date.self, forKey: .endTime)
            notes = try container.decode(String.self, forKey: .notes)
            linkTitles = try container.decode([String].self, forKey: .linkTitles)
            linkURLs = try container.decode([String].self, forKey: .linkURLs)
            enableDND = try container.decode(Bool.self, forKey: .enableDND)
            compactLeadingStyle = try container.decodeIfPresent(String.self, forKey: .compactLeadingStyle) ?? "capsule"
            minimalStyle = try container.decodeIfPresent(String.self, forKey: .minimalStyle) ?? "dot"
            expandedShowIcon = try container.decodeIfPresent(Bool.self, forKey: .expandedShowIcon) ?? true
            expandedShowTimer = try container.decodeIfPresent(Bool.self, forKey: .expandedShowTimer) ?? true
            expandedShowNotes = try container.decodeIfPresent(Bool.self, forKey: .expandedShowNotes) ?? true
            expandedShowLinks = try container.decodeIfPresent(Bool.self, forKey: .expandedShowLinks) ?? true
        }
    }

    var eventID: String
    var startTime: Date
}
