import Foundation
import SwiftData

class NetworkManager {
    static let shared = NetworkManager()
    private let extractURL = URL(string: "http://127.0.0.1:8000/extract")!
    private let extractPDFURL = URL(string: "http://127.0.0.1:8000/extract-pdf")!
    private let verifyURL = URL(string: "http://127.0.0.1:8000/verify")!

    func extractGraph(from text: String, context: ModelContext) async throws {
        let graph = try await postAndDecode(to: extractURL, body: ["text": text])
        insertGraph(graph, into: context)
    }

    func extractGraphFromPDF(filepath: String, context: ModelContext) async throws {
        let graph = try await postAndDecode(to: extractPDFURL, body: ["filepath": filepath])
        insertGraph(graph, into: context)
    }

    func verifyEdge(source: String, target: String, relationship: String) async throws -> Bool {
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(VerifyRequest(source: source, target: target, relationship: relationship))
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(VerifyResponse.self, from: data)
        return response.verified
    }

    private func postAndDecode(to url: URL, body: [String: String]) async throws -> GraphDTO {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GraphDTO.self, from: data)
    }

    private func insertGraph(_ graph: GraphDTO, into context: ModelContext) {
        // Insert nodes — skip if ID already exists in the database
        for nodeDTO in graph.nodes {
            let id = nodeDTO.id
            let existing = try? context.fetch(FetchDescriptor<ConceptNode>(
                predicate: #Predicate { $0.id == id }
            ))
            if existing?.isEmpty == true {
                context.insert(ConceptNode(id: id, label: nodeDTO.label, type: nodeDTO.type))
            }
        }

        // Insert edges — guard against self-loops as a safety net
        for edgeDTO in graph.edges {
            guard edgeDTO.source != edgeDTO.target else { continue }
            context.insert(ConnectionEdge(
                sourceNodeID: edgeDTO.source,
                targetNodeID: edgeDTO.target,
                relationship: edgeDTO.relationship
            ))
        }

        try? context.save()
    }
}
