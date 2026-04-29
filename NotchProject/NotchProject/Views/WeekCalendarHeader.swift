import SwiftUI
import SwiftData

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let events: [ScheduleEvent]

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            dayOfWeekRow
            calendarGrid
        }
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        shiftMonth(by: 1)
                    } else if value.translation.width > 50 {
                        shiftMonth(by: -1)
                    }
                }
        )
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(monthYearString)
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    displayedMonth = Date()
                    selectedDate = Date()
                }
            } label: {
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.top, 8)
    }

    private var dayOfWeekRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(daysInMonth, id: \.self) { date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayEvents = eventsOn(date)

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))

                HStack(spacing: 2) {
                    ForEach(dayEvents.prefix(3)) { event in
                        Circle()
                            .fill(isSelected ? .white : event.color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        withAnimation {
            displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        }
    }

    private func eventsOn(_ date: Date) -> [ScheduleEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }
}
