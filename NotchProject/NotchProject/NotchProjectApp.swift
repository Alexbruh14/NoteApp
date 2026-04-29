import SwiftUI
import SwiftData
import UserNotifications

@main
struct NotchProjectApp: App {
    let modelContainer: ModelContainer

    init() {
        NotificationManager.shared.registerAsDelegate()

        do {
            modelContainer = try ModelContainer(for: ScheduleEvent.self, EventPreset.self, EventLink.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestNotificationPermission()
                    startLiveActivitiesForActiveEvents()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "notchproject",
              url.host == "openlink",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let targetURL = URL(string: urlParam)
        else { return }

        UIApplication.shared.open(targetURL)
    }

    @MainActor
    private func startLiveActivitiesForActiveEvents() {
        let context = modelContainer.mainContext
        let now = Date()
        let descriptor = FetchDescriptor<ScheduleEvent>(
            predicate: #Predicate { event in
                event.startTime <= now && event.endTime > now
            }
        )

        guard let activeEvents = try? context.fetch(descriptor) else { return }

        for event in activeEvents {
            LiveActivityManager.shared.startActivityIfNeeded(for: event)
        }
    }
}
