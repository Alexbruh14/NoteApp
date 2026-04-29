import SwiftUI
import EventKit

struct SettingsView: View {
    @State private var settings = UserSettings.shared
    @State private var calendarService = CalendarService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        NotchCustomizationView()
                    } label: {
                        Label("Dynamic Island", systemImage: "capsule.portrait.fill")
                    }
                }

                Section("Event Defaults") {
                    Picker("Default Duration", selection: $settings.defaultDurationMinutes) {
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                    }

                    Picker("Reminder Before Event", selection: $settings.reminderOffsetMinutes) {
                        Text("At start time").tag(0)
                        Text("5 min before").tag(5)
                        Text("10 min before").tag(10)
                        Text("15 min before").tag(15)
                        Text("30 min before").tag(30)
                    }
                }

                Section("Timeline") {
                    Picker("Day Starts At", selection: $settings.timelineStartHour) {
                        ForEach(4..<12, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $settings.showEndNotifications) {
                        Label("End-of-Event Alerts", systemImage: "bell.badge")
                    }

                    Toggle(isOn: $settings.showActiveEventBadge) {
                        Label("App Badge for Active Events", systemImage: "app.badge")
                    }
                }

                Section {
                    Toggle(isOn: $settings.showCalendarEvents) {
                        Label("Show Apple Calendar Events", systemImage: "calendar")
                    }
                    .onChange(of: settings.showCalendarEvents) { _, enabled in
                        if enabled && !calendarService.isAuthorized {
                            Task { await calendarService.requestAccess() }
                        }
                    }

                    if settings.showCalendarEvents && !calendarService.isAuthorized {
                        Button {
                            Task { await calendarService.requestAccess() }
                        } label: {
                            Label("Connect Calendar", systemImage: "link.circle.fill")
                        }
                    }
                } header: {
                    Text("Calendar")
                } footer: {
                    Text("Reads events from your Apple Calendar and shows them alongside your scheduled time blocks.")
                }

                Section("Feedback") {
                    Toggle(isOn: $settings.hapticFeedbackEnabled) {
                        Label("Haptic Feedback", systemImage: "waveform")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}
