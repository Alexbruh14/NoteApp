import SwiftUI
import SwiftData

struct ImportantTopicsWidget: View {
    @Query private var nodes: [ConceptNode]
    @Query private var edges: [ConnectionEdge]
    @State private var isExpanded: Bool = true

    /// Nodes sorted by how many edges reference them (highest degree first).
    private var rankedNodes: [(node: ConceptNode, degree: Int)] {
        nodes.map { node in
            let degree = edges.filter { $0.sourceNodeID == node.id || $0.targetNodeID == node.id }.count
            return (node: node, degree: degree)
        }
        .sorted { $0.degree > $1.degree }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Important Topics")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                if rankedNodes.isEmpty {
                    Text("No nodes yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(rankedNodes.prefix(10), id: \.node.id) { item in
                                HStack {
                                    Circle()
                                        .fill(color(for: item.node.type))
                                        .frame(width: 10, height: 10)
                                    Text(item.node.label)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(item.degree)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .frame(width: 220)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }

    private func color(for type: String) -> Color {
        switch type {
        case "Person":  return Color(red: 0.10, green: 0.29, blue: 0.55)
        case "Concept": return Color(red: 0.10, green: 0.48, blue: 0.43)
        case "Book":    return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "Event":   return Color(red: 0.45, green: 0.19, blue: 0.55)
        case "Place":   return Color(red: 0.19, green: 0.45, blue: 0.19)
        default:        return .gray
        }
    }
}
