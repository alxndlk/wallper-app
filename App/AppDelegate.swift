import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let licenseManager = LicenseManager()
    let launchManager = LaunchManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        Env.shared.loadSyncFromLambda()
        NSApp.setActivationPolicy(.accessory)

        WindowManager.shared.showUpdateWindow(
            UpdateScreenView(launchManager: launchManager)
                .centerWindow()
                .frame(width: 300, height: 280)
        )

        launchManager.$isReady
            .receive(on: RunLoop.main)
            .sink { ready in
                if ready {
                    WindowManager.shared.hideUpdateWindow()
                    WindowManager.shared.setupStatusBarMenu()
                    WindowManager.shared.launchMainWindow(
                        licenseManager: self.licenseManager,
                        launchManager: self.launchManager
                    )
                }
            }
            .store(in: &WindowManager.shared.cancellables)
    }
}



