import SwiftUI

struct TransparentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TransparentWindowConfigurator())
    }
}

struct TransparentWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.titleVisibility = .hidden
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func makeWindowTransparent() -> some View {
        self.modifier(TransparentWindowModifier())
    }
}
