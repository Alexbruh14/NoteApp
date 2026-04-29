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
                if context.state.compactLeadingStyle == "icon" {
                    Image(systemName: context.state.presetIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: context.state.colorHex))
                } else {
                    Capsule()
                        .fill(Color(hex: context.state.colorHex))
                        .frame(width: 6, height: 14)
                }
            } compactTrailing: {
                Color.clear
                    .frame(width: 0)
            } minimal: {
                if context.state.minimalStyle == "icon" {
                    Image(systemName: context.state.presetIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: context.state.colorHex))
                } else {
                    Circle()
                        .fill(Color(hex: context.state.colorHex))
                        .frame(width: 10, height: 10)
                }
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
            if context.state.expandedShowIcon {
                Image(systemName: context.state.presetIcon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: context.state.colorHex))
                    .offset(x: 10, y: 13) //positioning of icon durring expanded view
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            if context.state.expandedShowTimer {
                Text(context.state.endTime, style: .timer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .offset(x: -8, y: 5) //positioning of timer
            }
        }

        DynamicIslandExpandedRegion(.center) {
            Text(context.state.eventTitle)
                .font(.headline)
                .lineLimit(1)
                .offset(x: -95, y: -3)
        }

        DynamicIslandExpandedRegion(.bottom) {
            VStack(alignment: .leading, spacing: 8) {
                if context.state.expandedShowNotes && !context.state.notes.isEmpty {
                    Text(context.state.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if context.state.expandedShowLinks && !context.state.linkURLs.isEmpty {
                    ForEach(Array(zip(context.state.linkTitles, context.state.linkURLs)), id: \.1) { title, urlString in
                        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let deepLink = URL(string: "notchproject://openlink?url=\(encoded)") {
                            Link(destination: deepLink) {
                                HStack(spacing: 6) {
                                    Image(systemName: urlString.lowercased().hasSuffix(".pdf") ? "doc.fill" : "safari")
                                        .font(.caption2)
                                    Text(title)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color(hex: context.state.colorHex))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(hex: context.state.colorHex).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
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
