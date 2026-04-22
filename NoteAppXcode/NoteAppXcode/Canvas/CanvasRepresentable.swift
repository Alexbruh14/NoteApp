import SwiftUI
import SpriteKit

/// Wraps the SpriteKit GraphScene for use in SwiftUI.
struct CanvasRepresentable: View {
    let scene: GraphScene

    init() {
        let s = GraphScene()
        s.size = CGSize(width: 800, height: 600)
        s.scaleMode = .resizeFill
        self.scene = s
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
