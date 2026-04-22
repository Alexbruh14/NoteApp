import SpriteKit

/// SpriteKit scene that renders the knowledge graph.
/// Nodes are displayed as labeled shapes, edges as lines between them.
class GraphScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black
        scaleMode = .resizeFill
    }

    // MARK: - Graph Rendering

    /// Clears the scene and draws the provided graph data.
    func renderGraph(nodes: [ConceptNode], edges: [ConnectionEdge]) {
        removeAllChildren()

        var spriteMap: [String: SKNode] = [:]

        // Create node sprites
        for node in nodes {
            let sprite = makeNodeSprite(for: node)
            sprite.position = CGPoint(x: node.positionX, y: node.positionY)
            addChild(sprite)
            spriteMap[node.id] = sprite
        }

        // Create edge lines
        for edge in edges {
            guard let source = spriteMap[edge.sourceNodeID],
                  let target = spriteMap[edge.targetNodeID] else { continue }
            let line = makeEdgeLine(from: source.position, to: target.position, label: edge.relationship)
            addChild(line)
        }
    }

    // MARK: - Sprite Factories

    private func makeNodeSprite(for node: ConceptNode) -> SKNode {
        let container = SKNode()
        container.name = node.id

        let circle = SKShapeNode(circleOfRadius: 30)
        circle.fillColor = color(for: node.type)
        circle.strokeColor = .white
        container.addChild(circle)

        let label = SKLabelNode(text: node.label)
        label.fontSize = 12
        label.fontName = "Helvetica-Bold"
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = 56
        label.numberOfLines = 2
        container.addChild(label)

        return container
    }

    private func makeEdgeLine(from start: CGPoint, to end: CGPoint, label: String) -> SKNode {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let line = SKShapeNode(path: path)
        line.strokeColor = .gray
        line.lineWidth = 1.5
        return line
    }

    private func color(for type: String) -> SKColor {
        switch type {
        case "Person":  return .systemBlue
        case "Concept": return .systemPurple
        case "Book":    return .systemOrange
        case "Event":   return .systemGreen
        case "Place":   return .systemRed
        default:        return .white
        }
    }
}
