struct NodeDTO: Codable {
    let id: String
    let label: String
    let type: String
}

struct EdgeDTO: Codable {
    let source: String
    let target: String
    let relationship: String
}

struct GraphDTO: Codable {
    let nodes: [NodeDTO]
    let edges: [EdgeDTO]
}
