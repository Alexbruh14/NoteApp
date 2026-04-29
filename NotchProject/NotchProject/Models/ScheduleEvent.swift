import Foundation
import SwiftData
import SwiftUI

@Model
final class ScheduleEvent {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var presetType: PresetType?
    var enableDND: Bool
    var colorHex: String

    @Relationship(deleteRule: .cascade)
    var links: [EventLink]

    init(
        title: String,
        startTime: Date,
        endTime: Date,
        notes: String = "",
        presetType: PresetType? = nil,
        enableDND: Bool = false,
        colorHex: String = "007AFF",
        links: [EventLink] = []
    ) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.presetType = presetType
        self.enableDND = enableDND
        self.colorHex = colorHex
        self.links = links
    }

    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }

    var color: Color {
        Color(hex: colorHex)
    }

    var presetIcon: String {
        presetType?.defaultIcon ?? "calendar"
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
