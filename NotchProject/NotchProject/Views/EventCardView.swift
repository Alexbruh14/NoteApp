import SwiftUI

struct EventCardView: View {
    let event: ScheduleEvent
    let hourHeight: CGFloat
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: event.presetIcon)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 20)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(event.formattedTimeRange)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))

                    if !event.notes.isEmpty && cardHeight > 60 {
                        Text(event.notes)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(cardHeight > 90 ? 2 : 1)
                    }

                    if !event.links.isEmpty && cardHeight > 80 {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 9))
                            Text("\(event.links.count) link\(event.links.count == 1 ? "" : "s")")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                if event.enableDND {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: cardHeight, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.color.gradient)
            )
            .clipped()
        }
        .buttonStyle(.plain)
    }

    private var cardHeight: CGFloat {
        let duration = event.endTime.timeIntervalSince(event.startTime)
        let hours = duration / 3600
        return max(hourHeight * hours, 36)
    }
}
