import SwiftUI
import SwiftData
import EventKit

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
    @State private var showingCreateReminder = false
    @State private var showingImportSheet = false
    @State private var editingEvent: ScheduleEvent?
    @State private var selectedCalendarEvent: EKEvent?
    @State private var fabExpanded = false
    @State private var settings = UserSettings.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    MonthCalendarView(selectedDate: $selectedDate, events: allEvents)
                    Divider()
                    eventList
                }

                if fabExpanded {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                fabExpanded = false
                            }
                        }
                        .transition(.opacity)
                }
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
            .sheet(isPresented: $showingCreateReminder) {
                CreateReminderSheet()
            }
            .sheet(isPresented: $showingImportSheet) {
                if let ekEvent = selectedCalendarEvent {
                    CreateEventSheet(importingFrom: ekEvent)
                }
            }
        }
    }

    // MARK: - Event List

    private var calendarEventsForSelectedDay: [EKEvent] {
        guard settings.showCalendarEvents else { return [] }
        return CalendarService.shared.events(for: selectedDate)
    }

    private var eventList: some View {
        let appEvents = eventsForSelectedDay
        let calEvents = calendarEventsForSelectedDay

        return Group {
            if appEvents.isEmpty && calEvents.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "calendar.badge.plus",
                    description: Text("Tap + to schedule a time block")
                )
            } else {
                List {
                    ForEach(appEvents) { event in
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

                    if !calEvents.isEmpty {
                        Section("From Apple Calendar") {
                            ForEach(calEvents, id: \.eventIdentifier) { ekEvent in
                                CalendarEventRowView(event: ekEvent) {
                                    selectedCalendarEvent = ekEvent
                                    showingImportSheet = true
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - FAB

    private var addButton: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if fabExpanded {
                fabSubButton(icon: "bell.fill", label: "Reminder", color: .orange) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { fabExpanded = false }
                    showingCreateReminder = true
                }

                fabSubButton(icon: "calendar", label: "Event", color: .blue) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { fabExpanded = false }
                    showingCreateEvent = true
                }
            }

            Button {
                if UserSettings.shared.hapticFeedbackEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    fabExpanded.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(fabExpanded ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(fabExpanded ? Color(.systemGray2) : .blue))
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: fabExpanded)
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func fabSubButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    )

                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(color))
                    .shadow(color: color.opacity(0.3), radius: 6, y: 3)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers

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
        if calendar.isDateInToday(selectedDate) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRowView: View {
    let event: EKEvent
    let onImport: () -> Void

    private var calendarColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .gray
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(calendarColor)
                .frame(width: 4)

            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(calendarColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled")
                    .font(.headline)

                Text(timeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onImport) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - App Event Row

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
