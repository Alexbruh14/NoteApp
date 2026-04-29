import Foundation
import SwiftData

enum PresetType: String, Codable, CaseIterable, Identifiable {
    case reading
    case homework
    case study
    case exercise
    case work
    case custom

    var id: String { rawValue }

    var defaultName: String {
        switch self {
        case .reading: "Reading"
        case .homework: "Homework"
        case .study: "Study"
        case .exercise: "Exercise"
        case .work: "Work"
        case .custom: "Custom"
        }
    }

    var defaultIcon: String {
        switch self {
        case .reading: "book.fill"
        case .homework: "pencil.and.ruler.fill"
        case .study: "brain.head.profile"
        case .exercise: "figure.run"
        case .work: "briefcase.fill"
        case .custom: "star.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .reading: "007AFF"
        case .homework: "FF9500"
        case .study: "AF52DE"
        case .exercise: "34C759"
        case .work: "8E8E93"
        case .custom: "FF2D55"
        }
    }

    var defaultDND: Bool {
        switch self {
        case .homework, .study: true
        default: false
        }
    }
}

@Model
final class EventPreset {
    var id: UUID
    var name: String
    var type: PresetType
    var defaultDND: Bool
    var color: String
    var icon: String

    init(name: String, type: PresetType, defaultDND: Bool? = nil, color: String? = nil, icon: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.defaultDND = defaultDND ?? type.defaultDND
        self.color = color ?? type.defaultColor
        self.icon = icon ?? type.defaultIcon
    }

    static func builtInPresets() -> [EventPreset] {
        PresetType.allCases.filter { $0 != .custom }.map { type in
            EventPreset(name: type.defaultName, type: type)
        }
    }
}
