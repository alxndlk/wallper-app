import SwiftUI

struct WindowAppearanceModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.94)
            .animation(.easeOut(duration: 0.25), value: isVisible)
            .onAppear {
                isVisible = true

                DispatchQueue.main.async {
                    if let window = NSApplication.shared.windows.first {
                        window.center()
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
    }
}

extension View {
    func animatedCenteredWindow() -> some View {
        self.modifier(WindowAppearanceModifier())
    }
}
