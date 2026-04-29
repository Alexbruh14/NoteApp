import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    static let startCategoryID = "EVENT_START"
    static let endCategoryID = "EVENT_END"
    static let snoozeActionID = "SNOOZE_5MIN"
    static let dismissActionID = "DISMISS"
    static let openLinksActionID = "OPEN_LINKS"

    override init() {
        super.init()
        registerCategories()
    }

    func registerAsDelegate() {
        center.delegate = self
    }

    // MARK: - Category Registration

    private func registerCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Snooze 5 min",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionID,
            title: "Dismiss",
            options: .destructive
        )

        let openLinksAction = UNNotificationAction(
            identifier: Self.openLinksActionID,
            title: "Open Links",
            options: .foreground
        )

        let startCategory = UNNotificationCategory(
            identifier: Self.startCategoryID,
            actions: [openLinksAction, snoozeAction, dismissAction],
            intentIdentifiers: []
        )

        let endCategory = UNNotificationCategory(
            identifier: Self.endCategoryID,
            actions: [dismissAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([startCategory, endCategory])
    }

    // MARK: - Schedule Notifications for an Event

    func scheduleNotifications(for event: ScheduleEvent) {
        removeNotifications(for: event)

        let settings = UserSettings.shared
        let offsetSeconds = TimeInterval(settings.reminderOffsetMinutes * 60)

        let startFireDate = event.startTime.addingTimeInterval(-offsetSeconds)
        if startFireDate > Date() {
            let startContent = UNMutableNotificationContent()
            startContent.title = event.title
            startContent.body = startNotificationBody(for: event)
            startContent.sound = .default
            startContent.categoryIdentifier = Self.startCategoryID
            startContent.userInfo = ["eventID": event.id.uuidString]

            let startTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: startFireDate
                ),
                repeats: false
            )

            let startRequest = UNNotificationRequest(
                identifier: startNotificationID(for: event),
                content: startContent,
                trigger: startTrigger
            )

            center.add(startRequest)
        }

        if settings.showEndNotifications && event.endTime > Date() {
            let endContent = UNMutableNotificationContent()
            endContent.title = "\(event.title) — Time's Up"
            endContent.body = "Your \(event.presetType?.defaultName ?? "scheduled") time is over."
            endContent.sound = .default
            endContent.categoryIdentifier = Self.endCategoryID
            endContent.userInfo = ["eventID": event.id.uuidString]

            let endTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: event.endTime
                ),
                repeats: false
            )

            let endRequest = UNNotificationRequest(
                identifier: endNotificationID(for: event),
                content: endContent,
                trigger: endTrigger
            )

            center.add(endRequest)
        }
    }

    func removeNotifications(for event: ScheduleEvent) {
        let ids = [startNotificationID(for: event), endNotificationID(for: event)]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func scheduleSnooze(for event: ScheduleEvent) {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Snoozed reminder — \(event.formattedTimeRange)"
        content.sound = .default
        content.categoryIdentifier = Self.startCategoryID
        content.userInfo = ["eventID": event.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)

        let request = UNNotificationRequest(
            identifier: "snooze-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let eventIDString = userInfo["eventID"] as? String else { return }

        switch response.actionIdentifier {
        case Self.snoozeActionID:
            NotificationCenter.default.post(
                name: .snoozeRequested,
                object: nil,
                userInfo: ["eventID": eventIDString]
            )

        case Self.openLinksActionID:
            NotificationCenter.default.post(
                name: .openLinksRequested,
                object: nil,
                userInfo: ["eventID": eventIDString]
            )

        default:
            break
        }
    }

    // MARK: - Helpers

    private func startNotificationID(for event: ScheduleEvent) -> String {
        "start-\(event.id.uuidString)"
    }

    private func endNotificationID(for event: ScheduleEvent) -> String {
        "end-\(event.id.uuidString)"
    }

    private func startNotificationBody(for event: ScheduleEvent) -> String {
        var parts: [String] = []
        parts.append(event.formattedTimeRange)

        if !event.notes.isEmpty {
            let preview = event.notes.prefix(100)
            parts.append(String(preview))
        }

        if !event.links.isEmpty {
            parts.append("\(event.links.count) link\(event.links.count == 1 ? "" : "s") attached")
        }

        if event.enableDND {
            parts.append("DND recommended")
        }

        return parts.joined(separator: " · ")
    }
}

extension Notification.Name {
    static let snoozeRequested = Notification.Name("snoozeRequested")
    static let openLinksRequested = Notification.Name("openLinksRequested")
}
