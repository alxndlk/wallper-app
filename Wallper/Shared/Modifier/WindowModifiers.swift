import SwiftUI

struct CustomWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowConfigurator())
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = WindowObservingView()
        view.configure = { window in
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isOpaque = false
            window.backgroundColor = .clear

            window.styleMask.insert(.titled)
            window.styleMask.insert(.closable)
            window.styleMask.insert(.miniaturizable)
            window.styleMask.insert(.resizable)

            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowObservingView: NSView {
    var configure: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            configure?(window)
        }
    }
}

extension View {
    func useCustomWindow() -> some View {
        self.modifier(CustomWindowModifier())
    }
}
