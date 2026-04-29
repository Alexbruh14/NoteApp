import SwiftUI
import SwiftData
import EventKit

struct PendingLink: Identifiable {
    let id = UUID()
    var title: String
    var urlString: String
    var type: LinkType
}

struct CreateEventSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingEvent: ScheduleEvent?
    var initialDate: Date

    // Pre-fill values set when importing from Apple Calendar
    private let importTitle: String?
    private let importStart: Date?
    private let importEnd: Date?
    private let importNotes: String?
    private let importColorHex: String?

    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var selectedPreset: PresetType?
    @State private var enableDND = false
    @State private var colorHex = "007AFF"
    @State private var showDNDPrompt = false
    @State private var linkURLString = ""
    @State private var linkTitle = ""
    @State private var pendingLinks: [PendingLink] = []
    @State private var showAddLink = false

    private var isEditing: Bool { editingEvent != nil }

    init(editingEvent: ScheduleEvent? = nil, initialDate: Date = Date()) {
        self.editingEvent = editingEvent
        self.initialDate = initialDate
        self.importTitle = nil
        self.importStart = nil
        self.importEnd = nil
        self.importNotes = nil
        self.importColorHex = nil
    }

    init(importingFrom ekEvent: EKEvent) {
        self.editingEvent = nil
        self.initialDate = ekEvent.startDate
        self.importTitle = ekEvent.title
        self.importStart = ekEvent.startDate
        self.importEnd = ekEvent.endDate
        self.importNotes = ekEvent.notes
        // Extract the calendar's color as a hex string
        var hex = "007AFF"
        if let cgColor = ekEvent.calendar?.cgColor,
           let comps = cgColor.components, comps.count >= 3 {
            let r = Int((comps[0] * 255).rounded())
            let g = Int((comps[1] * 255).rounded())
            let b = Int((comps[2] * 255).rounded())
            hex = String(format: "%02X%02X%02X", r, g, b)
        }
        self.importColorHex = hex
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                presetSection
                timeSection
                notesSection
                linksSection
                dndSection
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Enable Do Not Disturb?", isPresented: $showDNDPrompt) {
                Button("Enable DND") { enableDND = true }
                Button("No Thanks", role: .cancel) { enableDND = false }
            } message: {
                Text("The \(selectedPreset?.defaultName ?? "") preset recommends turning on Do Not Disturb during this time block.")
            }
            .onAppear {
                populateFields()
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("What are you scheduling?", text: $title)
                .font(.headline)
        }
    }

    private var presetSection: some View {
        Section("Activity Type") {    //Event Activity preset selector
            PresetSelectorView(selectedPreset: $selectedPreset) { preset in
                colorHex = preset.defaultColor
                if title.isEmpty {
                    title = preset.defaultName
                }
                if preset.defaultDND && !enableDND {
                    showDNDPrompt = true
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
        }
    }

    private var timeSection: some View {
        Section("Time Block") {
            DatePicker("From", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: startTime) {
                    if endTime <= startTime {
                        endTime = startTime.addingTimeInterval(3600)
                    }
                }
            DatePicker("To", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes to show in the reminder...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var linksSection: some View {
        Section("Links & Resources") {
            ForEach(pendingLinks) { link in
                HStack {
                    Image(systemName: link.type == .pdf ? "doc.fill" : "link")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(link.title)
                            .font(.subheadline)
                        Text(link.urlString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        pendingLinks.removeAll { $0.id == link.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showAddLink {
                addLinkFields
            } else {
                Button {
                    showAddLink = true
                } label: {
                    Label("Add Link", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var addLinkFields: some View {
        VStack(spacing: 12) {
            TextField("Link title (optional)", text: $linkTitle)
                .textContentType(.URL)

            TextField("https://...", text: $linkURLString)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()

            HStack {
                Button("Cancel") {
                    linkTitle = ""
                    linkURLString = ""
                    showAddLink = false
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Add Link") {
                    addLink()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(linkURLString.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 4)
    }

    private var dndSection: some View {
        Section {
            Toggle(isOn: $enableDND) {
                Label("Do Not Disturb", systemImage: "moon.fill")
            }
        } footer: {
            Text("When enabled, you'll be prompted to turn on Focus mode when this time block starts.")
        }
    }

    // MARK: - Helpers

    private func populateFields() {
        if let event = editingEvent {
            title = event.title
            startTime = event.startTime
            endTime = event.endTime
            notes = event.notes
            selectedPreset = event.presetType
            enableDND = event.enableDND
            colorHex = event.colorHex
            pendingLinks = event.links.map {
                PendingLink(title: $0.title, urlString: $0.urlString, type: $0.type)
            }
        } else if let s = importStart {
            title = importTitle ?? ""
            notes = importNotes ?? ""
            colorHex = importColorHex ?? "007AFF"
            startTime = s
            endTime = importEnd ?? s.addingTimeInterval(3600)
        } else {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: Date())
            let nextHour = max(hour + 1, 8)
            startTime = calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: initialDate) ?? initialDate
            endTime = startTime.addingTimeInterval(Double(UserSettings.shared.defaultDurationMinutes) * 60)
        }
    }

    private func saveEvent() {
        let eventLinks = pendingLinks.map {
            EventLink(title: $0.title, urlString: $0.urlString, type: $0.type)
        }

        if let event = editingEvent {
            event.title = title
            event.startTime = startTime
            event.endTime = endTime
            event.notes = notes
            event.presetType = selectedPreset
            event.enableDND = enableDND
            event.colorHex = colorHex
            event.links.forEach { modelContext.delete($0) }
            event.links = eventLinks
            NotificationManager.shared.scheduleNotifications(for: event)
            LiveActivityManager.shared.updateActivity(for: event)
        } else {
            let event = ScheduleEvent(
                title: title,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                presetType: selectedPreset,
                enableDND: enableDND,
                colorHex: colorHex,
                links: eventLinks
            )
            modelContext.insert(event)
            NotificationManager.shared.scheduleNotifications(for: event)
            print("[SaveEvent] Created '\(event.title)' start=\(event.startTime) end=\(event.endTime)")
            LiveActivityManager.shared.startActivityIfNeeded(for: event)
        }

        dismiss()
    }

    private func addLink() {
        let trimmed = linkURLString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let type: LinkType = trimmed.lowercased().hasSuffix(".pdf") ? .pdf : .webpage
        let name = linkTitle.trimmingCharacters(in: .whitespaces).isEmpty ? trimmed : linkTitle
        pendingLinks.append(PendingLink(title: name, urlString: trimmed, type: type))
        linkTitle = ""
        linkURLString = ""
        showAddLink = false
    }
}
