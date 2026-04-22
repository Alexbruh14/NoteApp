import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var noteText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
#if !os(macOS)
    @State private var showingPDFPicker: Bool = false
#endif

    var body: some View {
        HStack(spacing: 0) {
            // Left: physics canvas
            CanvasRepresentable()
                .frame(minWidth: 500)

            Divider()

            // Right: text editor
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $noteText)
                    .font(.body)
                    .border(Color.secondary.opacity(0.3))

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                HStack {
                    Button(isProcessing ? "Processing..." : "Extract to Graph") {
                        Task { await submitNote() }
                    }
                    .disabled(isProcessing || noteText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)

#if os(macOS)
                    Button("Import PDF") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.pdf]
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            Task {
                                try? await NetworkManager.shared.extractGraphFromPDF(
                                    filepath: url.path,
                                    context: context
                                )
                            }
                        }
                    }
                    .buttonStyle(.bordered)
#else
                    Button("Import PDF") {
                        showingPDFPicker = true
                    }
                    .buttonStyle(.bordered)
#endif
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            .frame(width: 320)
#if !os(macOS)
            .fileImporter(isPresented: $showingPDFPicker, allowedContentTypes: [.pdf]) { result in
                if case .success(let url) = result {
                    Task {
                        try? await NetworkManager.shared.extractGraphFromPDF(
                            filepath: url.path,
                            context: context
                        )
                    }
                }
            }
#endif
        }
    }

    private func submitNote() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        do {
            try await NetworkManager.shared.extractGraph(from: noteText, context: context)
        } catch {
            errorMessage = "Could not reach the backend. Is brain.py running?"
        }
    }
}
