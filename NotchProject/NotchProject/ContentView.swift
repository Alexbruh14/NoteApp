import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }

            Tab("Presets", systemImage: "square.stack.fill") {
                PresetsPlaceholderView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ScheduleEvent.startTime)
    private var allEvents: [ScheduleEvent]

    @State private var selectedDate = Date()
    @State private var showingCreateEvent = false
    @State private var editingEvent: ScheduleEvent?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCalendarView(selectedDate: $selectedDate, events: allEvents)

                Divider()

                eventList
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                addButton
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventSheet(initialDate: selectedDate)
            }
            .sheet(item: $editingEvent) { event in
                CreateEventSheet(editingEvent: event, initialDate: selectedDate)
            }
        }
    }

    private var eventList: some View {
        Group {
            if eventsForSelectedDay.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "calendar.badge.plus",
                    description: Text("Tap + to schedule a time block")
                )
            } else {
                List {
                    ForEach(eventsForSelectedDay) { event in
                        EventRowView(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { editingEvent = event }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var addButton: some View {
        Button {
            if UserSettings.shared.hapticFeedbackEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            showingCreateEvent = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(.blue))
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .padding(24)
    }

    private func deleteEvent(_ event: ScheduleEvent) {
        NotificationManager.shared.removeNotifications(for: event)
        LiveActivityManager.shared.stopActivity(for: event)
        modelContext.delete(event)
    }

    private var eventsForSelectedDay: [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return allEvents.filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
    }

    private var navigationTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
}

struct EventRowView: View {
    let event: ScheduleEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(event.color)
                .frame(width: 4)

            Image(systemName: event.presetIcon)
                .font(.title3)
                .foregroundStyle(event.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.formattedTimeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if event.isActive {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PresetsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Presets",
                systemImage: "square.stack.fill",
                description: Text("Custom preset management coming in Phase 5")
            )
            .navigationTitle("Presets")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ScheduleEvent.self, EventPreset.self, EventLink.self], inMemory: true)
}
