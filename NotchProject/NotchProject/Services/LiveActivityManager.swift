import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activeActivities: [String: String] = [:]

    private func contentState(for event: ScheduleEvent) -> ScheduleActivityAttributes.ContentState {
        ScheduleActivityAttributes.ContentState(
            eventTitle: event.title,
            presetIcon: event.presetIcon,
            colorHex: event.colorHex,
            endTime: event.endTime,
            notes: event.notes,
            linkTitles: event.links.map(\.title),
            linkURLs: event.links.map(\.urlString),
            enableDND: event.enableDND
        )
    }

    func startActivity(for event: ScheduleEvent) {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled on this device")
            return
        }
        guard event.endTime > Date() else {
            print("[LiveActivity] Event already ended, skipping")
            return
        }

        stopActivity(for: event)

        let attributes = ScheduleActivityAttributes(
            eventID: event.id.uuidString,
            startTime: min(event.startTime, Date())
        )

        let content = ActivityContent(state: contentState(for: event), staleDate: event.endTime)

        do {
            let activity = try Activity.request(attributes: attributes, content: content)
            activeActivities[event.id.uuidString] = activity.id
            print("[LiveActivity] Started for '\(event.title)' id=\(activity.id)")

            NotificationManager.shared.removeStartNotification(for: event)
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    func updateActivity(for event: ScheduleEvent) {
        guard let activityID = activeActivities[event.id.uuidString],
              let activity = Activity<ScheduleActivityAttributes>.activities.first(where: { $0.id == activityID })
        else { return }

        let content = ActivityContent(state: contentState(for: event), staleDate: event.endTime)
        Task { await activity.update(content) }
    }

    func stopActivity(for event: ScheduleEvent) {
        guard let activityID = activeActivities.removeValue(forKey: event.id.uuidString),
              let activity = Activity<ScheduleActivityAttributes>.activities.first(where: { $0.id == activityID })
        else { return }

        let finalState = ScheduleActivityAttributes.ContentState(
            eventTitle: event.title, presetIcon: event.presetIcon, colorHex: event.colorHex,
            endTime: event.endTime, notes: "", linkTitles: [], linkURLs: [], enableDND: false
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .immediate) }
    }

    func stopAllActivities() {
        Task {
            for activity in Activity<ScheduleActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            activeActivities.removeAll()
        }
    }

    func startActivityIfNeeded(for event: ScheduleEvent) {
        let now = Date()
        if event.startTime <= now.addingTimeInterval(60) && event.endTime > now {
            print("[LiveActivity] Event '\(event.title)' qualifies — starting")
            startActivity(for: event)
        } else {
            print("[LiveActivity] Event '\(event.title)' not active yet (starts: \(event.startTime), now: \(now))")
        }
    }
}
