import SpriteKit

class GraphScene: SKScene {

    // Track edges so we can redraw lines every frame
    private var edgePairs: [(sourceID: String, targetID: String, isVerified: Bool)] = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.97, alpha: 1.0)
        physicsWorld.gravity = .zero
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }

    // MARK: - Graph Building

    func addNode(id: String, label: String, type: String) {
        guard childNode(withName: id) == nil else { return }

        // Dynamic radius based on label length
        let baseRadius: CGFloat = 30
        let charWidth: CGFloat = 6.5
        let textWidth = CGFloat(label.count) * charWidth
        let radius = max(baseRadius, textWidth / 2 + 12)

        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.name = id
        bubble.fillColor = color(for: type)
        bubble.strokeColor = .white
        bubble.lineWidth = 2

        let minX: CGFloat = radius + 20
        let maxX = max(minX, frame.width - radius - 20)
        let minY: CGFloat = radius + 20
        let maxY = max(minY, frame.height - radius - 20)
        bubble.position = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )

        let physics = SKPhysicsBody(circleOfRadius: radius + 10)
        physics.isDynamic = true
        physics.restitution = 0.3
        physics.friction = 0.2
        physics.linearDamping = 0.8
        physics.allowsRotation = false
        bubble.physicsBody = physics

        let labelNode = SKLabelNode(text: label)
        labelNode.fontSize = 12
        labelNode.fontColor = .white
        labelNode.fontName = "Helvetica-Bold"
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.preferredMaxLayoutWidth = radius * 1.8
        labelNode.numberOfLines = 0
        bubble.addChild(labelNode)

        addChild(bubble)
    }

    func addEdge(from sourceID: String, to targetID: String, isVerified: Bool = false) {
        // Skip if we already track this edge
        let alreadyExists = edgePairs.contains { $0.sourceID == sourceID && $0.targetID == targetID }
        guard !alreadyExists else { return }

        guard
            let sourceNode = childNode(withName: sourceID) as? SKShapeNode,
            let targetNode = childNode(withName: targetID) as? SKShapeNode,
            let bodyA = sourceNode.physicsBody,
            let bodyB = targetNode.physicsBody
        else { return }

        let joint = SKPhysicsJointSpring.joint(
            withBodyA: bodyA,
            bodyB: bodyB,
            anchorA: sourceNode.position,
            anchorB: targetNode.position
        )
        joint.frequency = 0.8
        joint.damping = 0.4
        physicsWorld.add(joint)

        edgePairs.append((sourceID: sourceID, targetID: targetID, isVerified: isVerified))
    }

    // MARK: - Live Edge Rendering

    override func update(_ currentTime: TimeInterval) {
        // Remove old edge lines
        children.filter { $0.name == "edgeLine" }.forEach { $0.removeFromParent() }

        // Redraw edges at current node positions
        for edge in edgePairs {
            guard
                let sourceNode = childNode(withName: edge.sourceID),
                let targetNode = childNode(withName: edge.targetID)
            else { continue }

            let path = CGMutablePath()
            path.move(to: sourceNode.position)
            path.addLine(to: targetNode.position)
            let line = SKShapeNode(path: path)
            line.name = "edgeLine"
            line.strokeColor = SKColor(white: 0.4, alpha: 0.6)
            line.lineWidth = edge.isVerified ? 2.5 : 1.5
            line.zPosition = -1
            addChild(line)
        }
    }

    // MARK: - Colors

    private func color(for type: String) -> SKColor {
        switch type {
        case "Person":  return SKColor(red: 0.10, green: 0.29, blue: 0.55, alpha: 1)
        case "Concept": return SKColor(red: 0.10, green: 0.48, blue: 0.43, alpha: 1)
        case "Book":    return SKColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        case "Event":   return SKColor(red: 0.45, green: 0.19, blue: 0.55, alpha: 1)
        case "Place":   return SKColor(red: 0.19, green: 0.45, blue: 0.19, alpha: 1)
        default:        return .darkGray
        }
    }

    // MARK: - Drag Interaction
    private var draggedNode: SKShapeNode?

#if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        draggedNode = nodes(at: location).compactMap { $0 as? SKShapeNode }.first
        draggedNode?.physicsBody?.isDynamic = false
    }

    override func mouseDragged(with event: NSEvent) {
        draggedNode?.position = event.location(in: self)
    }

    override func mouseUp(with event: NSEvent) {
        draggedNode?.physicsBody?.isDynamic = true
        draggedNode = nil
    }
#else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        draggedNode = nodes(at: location).compactMap { $0 as? SKShapeNode }.first
        draggedNode?.physicsBody?.isDynamic = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        draggedNode?.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggedNode?.physicsBody?.isDynamic = true
        draggedNode = nil
    }
#endif
}
