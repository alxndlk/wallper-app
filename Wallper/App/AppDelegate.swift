import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @Published var isReady: Bool = false
    let licenseManager = LicenseManager()
    let launchManager = LaunchManager()
}
    
