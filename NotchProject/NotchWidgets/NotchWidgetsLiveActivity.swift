import ActivityKit
import WidgetKit
import SwiftUI

struct NotchWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScheduleActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                expandedView(context: context)
            } compactLeading: {
                Capsule()
                    .fill(Color(hex: context.state.colorHex))
                    .frame(width: 6, height: 14)
            } compactTrailing: {
                Color.clear
                    .frame(width: 0)
            } minimal: {
                Circle()
                    .fill(Color(hex: context.state.colorHex))
                    .frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ScheduleActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: context.state.colorHex))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.eventTitle)
                    .font(.headline)

                if !context.state.notes.isEmpty {
                    Text(context.state.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if !context.state.linkURLs.isEmpty {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    @DynamicIslandExpandedContentBuilder
    private func expandedView(context: ActivityViewContext<ScheduleActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: context.state.colorHex))
                .frame(width: 4, height: 30)
        }

        DynamicIslandExpandedRegion(.trailing) {
            Text(context.state.eventTitle)
                .font(.headline)
                .lineLimit(1)
        }

        DynamicIslandExpandedRegion(.bottom) {
            VStack(alignment: .leading, spacing: 8) {
                if !context.state.notes.isEmpty {
                    Text(context.state.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !context.state.linkURLs.isEmpty {
                    ForEach(Array(zip(context.state.linkTitles, context.state.linkURLs)), id: \.1) { title, urlString in
                        if let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: urlString.lowercased().hasSuffix(".pdf") ? "doc.fill" : "link")
                                        .font(.caption2)
                                    Text(title)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .foregroundStyle(Color(hex: context.state.colorHex))
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
