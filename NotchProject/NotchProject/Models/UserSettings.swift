import Foundation
import SwiftUI

@Observable
final class UserSettings {
    static let shared = UserSettings()

    var defaultDurationMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "defaultDuration").nonZero ?? 60 }
        set { UserDefaults.standard.set(newValue, forKey: "defaultDuration") }
    }

    var timelineStartHour: Int {
        get { UserDefaults.standard.integer(forKey: "timelineStartHour").nonZero ?? 6 }
        set { UserDefaults.standard.set(newValue, forKey: "timelineStartHour") }
    }

    var reminderOffsetMinutes: Int {
        get {
            let val = UserDefaults.standard.object(forKey: "reminderOffset") as? Int
            return val ?? 5
        }
        set { UserDefaults.standard.set(newValue, forKey: "reminderOffset") }
    }

    var hapticFeedbackEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticFeedback") }
    }

    var showEndNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "showEndNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showEndNotifications") }
    }

    var showActiveEventBadge: Bool {
        get { UserDefaults.standard.object(forKey: "showActiveEventBadge") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showActiveEventBadge") }
    }
}

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
