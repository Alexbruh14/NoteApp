import SwiftUI

enum IslandPreviewMode: String, CaseIterable {
    case compact = "Compact"
    case expanded = "Expanded"
    case minimal = "Minimal"
}

struct NotchCustomizationView: View {
    @State private var settings = UserSettings.shared
    @State private var previewMode: IslandPreviewMode = .expanded

    private let sampleColor = "007AFF"
    private let sampleIcon = "book.fill"

    var body: some View {
        List {
            previewSection

            switch previewMode {
            case .compact:
                compactSettingsSection
            case .expanded:
                expandedSettingsSection
            case .minimal:
                minimalSettingsSection
            }
        }
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.compactLeadingStyle) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
        .onChange(of: settings.minimalStyle) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
        .onChange(of: settings.expandedShowIcon) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
        .onChange(of: settings.expandedShowTimer) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
        .onChange(of: settings.expandedShowNotes) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
        .onChange(of: settings.expandedShowLinks) { _, _ in
            LiveActivityManager.shared.updateAllActivitiesForSettingsChange()
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            VStack(spacing: 20) {
                Picker("Preview", selection: $previewMode) {
                    ForEach(IslandPreviewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                islandPreview
                    .animation(.easeInOut(duration: 0.25), value: previewMode)
                    .animation(.easeInOut(duration: 0.25), value: settings.compactLeadingStyle)
                    .animation(.easeInOut(duration: 0.25), value: settings.minimalStyle)
                    .animation(.easeInOut(duration: 0.25), value: settings.expandedShowIcon)
                    .animation(.easeInOut(duration: 0.25), value: settings.expandedShowTimer)
                    .animation(.easeInOut(duration: 0.25), value: settings.expandedShowNotes)
                    .animation(.easeInOut(duration: 0.25), value: settings.expandedShowLinks)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    @ViewBuilder
    private var islandPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))

            VStack {
                switch previewMode {
                case .compact:
                    compactMockup
                case .expanded:
                    expandedMockup
                case .minimal:
                    minimalMockup
                }
            }
            .padding(20)
        }
        .frame(height: previewHeight)
    }

    private var previewHeight: CGFloat {
        switch previewMode {
        case .compact: return 100
        case .expanded:
            var h: CGFloat = 120
            if settings.expandedShowNotes { h += 28 }
            if settings.expandedShowLinks { h += 44 }
            return h
        case .minimal: return 100
        }
    }

    // MARK: - Compact Mockup

    private var compactMockup: some View {
        HStack(spacing: 0) {
            Group {
                if settings.compactLeadingStyle == "icon" {
                    Image(systemName: sampleIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: sampleColor))
                } else {
                    Capsule()
                        .fill(Color(hex: sampleColor))
                        .frame(width: 6, height: 14)
                }
            }
            .frame(width: 30)

            Spacer().frame(width: 12)

            Circle()
                .fill(Color(white: 0.12))
                .frame(width: 14, height: 14)

            Spacer().frame(width: 12)

            Color.clear.frame(width: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Capsule().fill(.black))
    }

    // MARK: - Expanded Mockup

    private var expandedMockup: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                if settings.expandedShowIcon {
                    Image(systemName: sampleIcon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: sampleColor))
                }

                Text("Study Session")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if settings.expandedShowTimer {
                    Text("1:23:45")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
            }

            if settings.expandedShowNotes {
                Text("Chapter 5-7, review notes")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }

            if settings.expandedShowLinks {
                HStack(spacing: 6) {
                    Image(systemName: "safari")
                        .font(.caption2)
                    Text("Course Slides")
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                }
                .foregroundStyle(Color(hex: sampleColor))
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color(hex: sampleColor).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.black)
        )
    }

    // MARK: - Minimal Mockup

    private var minimalMockup: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(.black)
                .frame(width: 52, height: 36)

            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 36, height: 36)

                if settings.minimalStyle == "icon" {
                    Image(systemName: sampleIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: sampleColor))
                } else {
                    Circle()
                        .fill(Color(hex: sampleColor))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    // MARK: - Settings Sections

    private var compactSettingsSection: some View {
        Section {
            Picker("Leading Indicator", selection: $settings.compactLeadingStyle) {
                Text("Color Capsule").tag("capsule")
                Text("Preset Icon").tag("icon")
            }
        } header: {
            Text("Compact Settings")
        } footer: {
            Text("The resting state of the Dynamic Island when your event is active.")
        }
    }

    private var minimalSettingsSection: some View {
        Section {
            Picker("Indicator Style", selection: $settings.minimalStyle) {
                Text("Color Dot").tag("dot")
                Text("Preset Icon").tag("icon")
            }
        } header: {
            Text("Minimal Settings")
        } footer: {
            Text("Shown when another app is also using the Dynamic Island.")
        }
    }

    private var expandedSettingsSection: some View {
        Section {
            Toggle("Preset Icon", isOn: $settings.expandedShowIcon)
            Toggle("Countdown Timer", isOn: $settings.expandedShowTimer)
            Toggle("Notes", isOn: $settings.expandedShowNotes)
            Toggle("Links", isOn: $settings.expandedShowLinks)
        } header: {
            Text("Expanded Settings")
        } footer: {
            Text("Content shown when you press and hold the Dynamic Island. Changes apply instantly to active events.")
        }
    }
}
