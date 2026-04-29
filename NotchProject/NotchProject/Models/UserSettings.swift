import Foundation
import SwiftUI

@Observable
final class UserSettings {
    static let shared = UserSettings()

    var defaultDurationMinutes: Int { didSet { UserDefaults.standard.set(defaultDurationMinutes, forKey: "defaultDuration") } }
    var timelineStartHour: Int      { didSet { UserDefaults.standard.set(timelineStartHour, forKey: "timelineStartHour") } }
    var reminderOffsetMinutes: Int  { didSet { UserDefaults.standard.set(reminderOffsetMinutes, forKey: "reminderOffset") } }
    var hapticFeedbackEnabled: Bool { didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedback") } }
    var showEndNotifications: Bool  { didSet { UserDefaults.standard.set(showEndNotifications, forKey: "showEndNotifications") } }
    var showActiveEventBadge: Bool  { didSet { UserDefaults.standard.set(showActiveEventBadge, forKey: "showActiveEventBadge") } }

    // MARK: - Dynamic Island Customization

    var compactLeadingStyle: String { didSet { UserDefaults.standard.set(compactLeadingStyle, forKey: "compactLeadingStyle") } }
    var minimalStyle: String        { didSet { UserDefaults.standard.set(minimalStyle, forKey: "minimalStyle") } }
    var expandedShowIcon: Bool      { didSet { UserDefaults.standard.set(expandedShowIcon, forKey: "expandedShowIcon") } }
    var expandedShowTimer: Bool     { didSet { UserDefaults.standard.set(expandedShowTimer, forKey: "expandedShowTimer") } }
    var expandedShowNotes: Bool     { didSet { UserDefaults.standard.set(expandedShowNotes, forKey: "expandedShowNotes") } }
    var expandedShowLinks: Bool     { didSet { UserDefaults.standard.set(expandedShowLinks, forKey: "expandedShowLinks") } }

    // MARK: - Calendar Integration

    var showCalendarEvents: Bool    { didSet { UserDefaults.standard.set(showCalendarEvents, forKey: "showCalendarEvents") } }

    private init() {
        let ud = UserDefaults.standard
        defaultDurationMinutes = (ud.integer(forKey: "defaultDuration").nonZero) ?? 60
        timelineStartHour      = (ud.integer(forKey: "timelineStartHour").nonZero) ?? 6
        reminderOffsetMinutes  = ud.object(forKey: "reminderOffset") as? Int ?? 5
        hapticFeedbackEnabled  = ud.object(forKey: "hapticFeedback") as? Bool ?? true
        showEndNotifications   = ud.object(forKey: "showEndNotifications") as? Bool ?? true
        showActiveEventBadge   = ud.object(forKey: "showActiveEventBadge") as? Bool ?? true
        compactLeadingStyle    = ud.string(forKey: "compactLeadingStyle") ?? "capsule"
        minimalStyle           = ud.string(forKey: "minimalStyle") ?? "dot"
        expandedShowIcon       = ud.object(forKey: "expandedShowIcon") as? Bool ?? true
        expandedShowTimer      = ud.object(forKey: "expandedShowTimer") as? Bool ?? true
        expandedShowNotes      = ud.object(forKey: "expandedShowNotes") as? Bool ?? true
        expandedShowLinks      = ud.object(forKey: "expandedShowLinks") as? Bool ?? true
        showCalendarEvents     = ud.object(forKey: "showCalendarEvents") as? Bool ?? false
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
