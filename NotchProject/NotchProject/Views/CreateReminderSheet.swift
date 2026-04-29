import SwiftUI

struct CreateReminderSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var fireDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you want to be reminded of?", text: $title)
                        .font(.headline)
                }

                Section("Notes") {
                    TextField("Additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Remind me at") {
                    DatePicker(
                        "",
                        selection: $fireDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveReminder() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveReminder() {
        NotificationManager.shared.scheduleReminder(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            fireDate: fireDate
        )
        dismiss()
    }
}
