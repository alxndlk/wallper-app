import SwiftUI

struct WindowCenterModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.windows.first?.center()
                }
            }
    }
}

extension View {
    func centerWindow() -> some View {
        self.modifier(WindowCenterModifier())
    }
}
