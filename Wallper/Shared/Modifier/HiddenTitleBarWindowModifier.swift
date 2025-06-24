import SwiftUI
import AppKit

struct HiddenTitleBarWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TitleBarConfigurator())
    }

    private struct TitleBarConfigurator: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let nsView = NSView()
            DispatchQueue.main.async {
                if let window = nsView.window {
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                }
            }
            return nsView
        }

        func updateNSView(_ nsView: NSView, context: Context) {}
    }
}

extension View {
    func hiddenTitleBarStyle() -> some View {
        self.modifier(HiddenTitleBarWindowModifier())
    }
}
