import SwiftUI
import SwiftData

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
    @State private var durationMinutes = 60

    private var isEditing: Bool { editingEvent != nil }

    init(editingEvent: ScheduleEvent? = nil, initialDate: Date = Date()) {
        self.editingEvent = editingEvent
        self.initialDate = initialDate
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
        Section("Activity Type") {
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
            DatePicker("Starts", selection: $startTime)

            Picker("Duration", selection: $durationMinutes) {
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("45 min").tag(45)
                Text("1 hour").tag(60)
                Text("1.5 hours").tag(90)
                Text("2 hours").tag(120)
                Text("2.5 hours").tag(150)
                Text("3 hours").tag(180)
                Text("4 hours").tag(240)
            }
            .onChange(of: durationMinutes) {
                endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
            }
            .onChange(of: startTime) {
                endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
            }

            HStack {
                Text("Ends")
                Spacer()
                Text(endTimeString)
                    .foregroundStyle(.secondary)
            }
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
            durationMinutes = Int(event.duration / 60)
            pendingLinks = event.links.map {
                PendingLink(title: $0.title, urlString: $0.urlString, type: $0.type)
            }
        } else {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: Date())
            let nextHour = max(hour + 1, 8)
            startTime = calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: initialDate) ?? initialDate
            durationMinutes = UserSettings.shared.defaultDurationMinutes
            endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
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

    private var endTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
}
