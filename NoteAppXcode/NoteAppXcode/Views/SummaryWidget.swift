import SwiftUI

struct SummaryWidget: View {
    @State private var summaryText: String = ""
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Summary")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                TextEditor(text: $summaryText)
                    .font(.body)
                    .frame(width: 280, height: 160)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 300)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
}
