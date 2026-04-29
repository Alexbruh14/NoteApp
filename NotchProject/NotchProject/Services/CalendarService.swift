import EventKit
import Foundation

@Observable
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()
    private(set) var status: EKAuthorizationStatus

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized // swiftlint:disable:this legacy_objc_type
        }
    }

    private init() {
        status = EKEventStore.authorizationStatus(for: .event)
    }

    @MainActor
    func requestAccess() async {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestFullAccessToEvents()
                status = granted ? .fullAccess : .denied
            } else {
                let granted = try await store.requestAccess(to: .event)
                status = granted ? .authorized : .denied
            }
        } catch {
            print("[CalendarService] Access request failed: \(error)")
            status = .denied
        }
    }

    func events(for date: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
}
