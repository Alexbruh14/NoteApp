import SwiftUI
import SpriteKit
import SwiftData

#if os(macOS)
struct CanvasRepresentable: NSViewRepresentable {
    @Query private var nodes: [ConceptNode]
    @Query private var edges: [ConnectionEdge]

    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = GraphScene(size: CGSize(width: 700, height: 600))
        scene.scaleMode = .resizeFill
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
    }
}
#else
struct CanvasRepresentable: UIViewRepresentable {
    @Query private var nodes: [ConceptNode]
    @Query private var edges: [ConnectionEdge]

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = GraphScene(size: CGSize(width: 700, height: 600))
        scene.scaleMode = .resizeFill
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
    }
}
#endif
