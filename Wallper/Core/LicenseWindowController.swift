import AppKit
import SwiftUI

final class LicenseWindowController {
    static var shared: NSWindow?

    static func show(licenseManager: LicenseManager) {
        if let existing = shared {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = LicenseWindowView()
            .environmentObject(licenseManager)

        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Activate Wallper"
        window.isReleasedWhenClosed = false
        window.contentView = hostingController.view
        window.makeKeyAndOrderFront(nil)
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.backgroundColor = .clear
        window.isOpaque = true
        window.appearance = NSAppearance(named: .darkAqua)

        NSApp.activate(ignoringOtherApps: true)

        shared = window

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            shared = nil
        }
    }
}
