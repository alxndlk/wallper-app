import SwiftUI

enum CustomWindowStyle {
    case update
}

extension NSWindow {

    convenience init(contentRect: CGRect, customStyle: CustomWindowStyle) {
        switch customStyle {
        case .update:
            let styleMask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView]
            self.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)

            titlebarAppearsTransparent = true
            titleVisibility = .hidden
            standardWindowButton(.zoomButton)?.isHidden = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true

            isOpaque = false
            backgroundColor = .clear
            hasShadow = true
            isMovableByWindowBackground = true
            appearance = NSAppearance(named: .darkAqua)
        }
    }
}
