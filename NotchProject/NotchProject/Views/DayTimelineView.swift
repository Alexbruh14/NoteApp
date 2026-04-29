import SwiftUI
import SwiftData

struct DayTimelineView: View {
    let events: [ScheduleEvent]
    let selectedDate: Date
    var onEventTap: (ScheduleEvent) -> Void = { _ in }

    private let hourHeight: CGFloat = 60
    private let startHour = 6
    private let endHour = 24
    private let leadingWidth: CGFloat = 50

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    hourGrid
                    currentTimeLine
                    eventsOverlay
                }
                .frame(height: totalHeight)
                .id("timeline")
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
            .onChange(of: selectedDate) {
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    Text(hourString(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: leadingWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -6)

                    VStack(spacing: 0) {
                        Divider()
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    private var currentTimeLine: some View {
        GeometryReader { _ in
            let calendar = Calendar.current
            if calendar.isDate(selectedDate, inSameDayAs: Date()) {
                let now = Date()
                let hour = calendar.component(.hour, from: now)
                let minute = calendar.component(.minute, from: now)
                let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

                if yOffset >= 0 && yOffset <= totalHeight {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .offset(x: leadingWidth - 4)

                        Rectangle()
                            .fill(.red)
                            .frame(height: 1)
                    }
                    .offset(y: yOffset)
                }
            }
        }
    }

    private var eventsOverlay: some View {
        let dayEvents = eventsForSelectedDay
        return ForEach(dayEvents) { event in
            let yOffset = yPosition(for: event.startTime)
            let cardHeight = max(
                hourHeight * event.endTime.timeIntervalSince(event.startTime) / 3600,
                36
            )

            EventCardView(event: event, hourHeight: hourHeight) {
                onEventTap(event)
            }
            .frame(height: cardHeight)
            .padding(.leading, leadingWidth + 12)
            .padding(.trailing, 16)
            .offset(y: yOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var eventsForSelectedDay: [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
    }

    private func yPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private var totalHeight: CGFloat {
        CGFloat(endHour - startHour) * hourHeight
    }

    private func hourString(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let scrollTo = max(currentHour - 1, startHour)
        withAnimation {
            proxy.scrollTo(scrollTo, anchor: .top)
        }
    }
}
