import SwiftUI

@main
struct WallperApp: App {
    @StateObject private var launchManager = LaunchManager()
    @StateObject private var licenseManager = LicenseManager()
    @State private var licenseRenderID = UUID()
    @State private var licenseWindowShown = false

    var body: some Scene {
        WindowGroup {
            Group {
                if launchManager.isReady {
                    MainContentView()
                        .id(licenseRenderID)
                        .environmentObject(licenseManager)
                        .centerWindow()
                        .useCustomWindow()
                        .frame(minWidth: 1300, minHeight: 768)
                        .onAppear {
                            if licenseManager.hasLicense && !licenseWindowShown {
                                LicenseWindowController.show(licenseManager: licenseManager)
                                licenseWindowShown = true
                            }
                        }
                        .onChange(of: licenseManager.hasLicense) { hasLicense in
                            licenseRenderID = UUID()

                            if hasLicense {
                                LicenseWindowController()
                            }
                        }
                } else {
                    UpdateScreenView(launchManager: launchManager)
                        .centerWindow()
                        .useCustomWindow()
                        .frame(width: 300, height: 280)
                }
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
}
