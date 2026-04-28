import SpriteKit

class GraphScene: SKScene {

    // Track edges so we can redraw lines every frame
    private var edgePairs: [(sourceID: String, targetID: String, isVerified: Bool)] = []

    /// Called when the user requests verification of an edge (right-click on macOS, long-press on iPad).
    /// Parameters are (sourceNodeID, targetNodeID).
    var onVerifyEdge: ((String, String) -> Void)?

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

    /// Update the verification status of an edge in the scene's tracking array.
    func updateEdgeVerification(sourceID: String, targetID: String) {
        if let index = edgePairs.firstIndex(where: { $0.sourceID == sourceID && $0.targetID == targetID }) {
            edgePairs[index].isVerified = true
        }
    }

    /// Sync all edge verification states from the data layer.
    func syncVerification(_ edges: [(sourceID: String, targetID: String, isVerified: Bool)]) {
        for edge in edges {
            if let index = edgePairs.firstIndex(where: { $0.sourceID == edge.sourceID && $0.targetID == edge.targetID }) {
                edgePairs[index].isVerified = edge.isVerified
            }
        }
    }

    // MARK: - Live Edge Rendering

    override func update(_ currentTime: TimeInterval) {
        children.filter { $0.name == "edgeLine" }.forEach { $0.removeFromParent() }

        for edge in edgePairs {
            guard
                let sourceNode = childNode(withName: edge.sourceID),
                let targetNode = childNode(withName: edge.targetID)
            else { continue }

            let path = CGMutablePath()
            path.move(to: sourceNode.position)
            path.addLine(to: targetNode.position)

            let line: SKShapeNode
            if edge.isVerified {
                line = SKShapeNode(path: path)
                line.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.8)
                line.lineWidth = 2.5
            } else {
                // Dashed line for unverified edges
                let dashedPath = path.copy(dashingWithPhase: 0, lengths: [8, 6])
                line = SKShapeNode(path: dashedPath)
                line.strokeColor = SKColor(white: 0.4, alpha: 0.5)
                line.lineWidth = 1.5
            }
            line.name = "edgeLine"
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

    // MARK: - Edge Hit Detection

    /// Find the closest edge to a point, within a threshold distance.
    private func nearestEdge(to point: CGPoint, threshold: CGFloat = 15) -> (sourceID: String, targetID: String)? {
        var bestDistance: CGFloat = threshold
        var bestEdge: (sourceID: String, targetID: String)?

        for edge in edgePairs {
            guard
                let sourceNode = childNode(withName: edge.sourceID),
                let targetNode = childNode(withName: edge.targetID)
            else { continue }

            let dist = distanceFromPoint(point, toSegmentFrom: sourceNode.position, to: targetNode.position)
            if dist < bestDistance {
                bestDistance = dist
                bestEdge = (sourceID: edge.sourceID, targetID: edge.targetID)
            }
        }
        return bestEdge
    }

    private func distanceFromPoint(_ p: CGPoint, toSegmentFrom a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else { return hypot(p.x - a.x, p.y - a.y) }

        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSq))
        let projX = a.x + t * dx
        let projY = a.y + t * dy
        return hypot(p.x - projX, p.y - projY)
    }

    // MARK: - Drag & Verify Interaction
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

    override func rightMouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        if let edge = nearestEdge(to: location) {
            onVerifyEdge?(edge.sourceID, edge.targetID)
        }
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
