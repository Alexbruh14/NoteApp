import SwiftUI
import SpriteKit
import SwiftData

#if os(macOS)
struct CanvasRepresentable: NSViewRepresentable {
    @Query private var nodes: [ConceptNode]
    @Query private var edges: [ConnectionEdge]
    @Environment(\.modelContext) private var context

    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = GraphScene(size: CGSize(width: 700, height: 600))
        scene.scaleMode = .resizeFill
        scene.onVerifyEdge = { [self] sourceID, targetID in
            verifyEdge(sourceID: sourceID, targetID: targetID, scene: scene)
        }
        view.presentScene(scene)
        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        guard let scene = nsView.scene as? GraphScene else { return }
        for node in nodes {
            scene.addNode(id: node.id, label: node.label, type: node.type)
        }
        for edge in edges {
            scene.addEdge(from: edge.sourceNodeID, to: edge.targetNodeID, isVerified: edge.isVerified)
        }
        scene.syncVerification(edges.map { (sourceID: $0.sourceNodeID, targetID: $0.targetNodeID, isVerified: $0.isVerified) })
    }

    private func verifyEdge(sourceID: String, targetID: String, scene: GraphScene) {
        guard let edge = edges.first(where: { $0.sourceNodeID == sourceID && $0.targetNodeID == targetID }) else { return }
        Task {
            let verified = try await NetworkManager.shared.verifyEdge(
                source: sourceID,
                target: targetID,
                relationship: edge.relationship
            )
            if verified {
                await MainActor.run {
                    edge.isVerified = true
                    try? self.context.save()
                    scene.updateEdgeVerification(sourceID: sourceID, targetID: targetID)
                }
            }
        }
    }
}
#else
struct CanvasRepresentable: UIViewRepresentable {
    @Query private var nodes: [ConceptNode]
    @Query private var edges: [ConnectionEdge]
    @Environment(\.modelContext) private var context

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = GraphScene(size: CGSize(width: 700, height: 600))
        scene.scaleMode = .resizeFill
        scene.onVerifyEdge = { [self] sourceID, targetID in
            verifyEdge(sourceID: sourceID, targetID: targetID, scene: scene)
        }
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? GraphScene else { return }
        for node in nodes {
            scene.addNode(id: node.id, label: node.label, type: node.type)
        }
        for edge in edges {
            scene.addEdge(from: edge.sourceNodeID, to: edge.targetNodeID, isVerified: edge.isVerified)
        }
        scene.syncVerification(edges.map { (sourceID: $0.sourceNodeID, targetID: $0.targetNodeID, isVerified: $0.isVerified) })
    }

    private func verifyEdge(sourceID: String, targetID: String, scene: GraphScene) {
        guard let edge = edges.first(where: { $0.sourceNodeID == sourceID && $0.targetNodeID == targetID }) else { return }
        Task {
            let verified = try await NetworkManager.shared.verifyEdge(
                source: sourceID,
                target: targetID,
                relationship: edge.relationship
            )
            if verified {
                await MainActor.run {
                    edge.isVerified = true
                    try? self.context.save()
                    scene.updateEdgeVerification(sourceID: sourceID, targetID: targetID)
                }
            }
        }
    }
}
#endif
