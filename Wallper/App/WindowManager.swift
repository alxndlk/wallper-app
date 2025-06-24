import Foundation
import SwiftUI
import Combine
import IOKit
import IOKit.ps
import Charts
import MachO


class WindowManager: NSObject, ObservableObject {
    static let shared = WindowManager()
    let licenseManager = LicenseManager()
    let launchManager = LaunchManager()

    var cancellables = Set<AnyCancellable>()
    private var usageTimer: Timer?

    private(set) var mainWindow: NSWindow?
    private(set) var updateWindow: NSWindow?
    private(set) var wallpaperWindows: [NSWindow] = []
    private var statusItem: NSStatusItem?

    private var openItem: NSMenuItem?
    private var closeItem: NSMenuItem?
    private var cpuItem: NSMenuItem?
    private var ramItem: NSMenuItem?
    private var batteryItem: NSMenuItem?

    private var usageWindow: NSWindow?
    private var history = UsageStatsHistory()

    private var previousTotalTicks: UInt64 = 0
    private var previousIdleTicks: UInt64 = 0

    override init() {
        super.init()
    }

    func showMainWindow<Content: View>(_ view: Content) {
        
        if mainWindow != nil {
            mainWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
        let initialSize = NSSize(width: 1300, height: 768)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.contentMinSize = initialSize

        let hostingView = NSHostingView(rootView: view)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hostingView

        window.center()
        window.delegate = self
        mainWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateMenuState()
    }




    func closeMainWindow() {
        mainWindow?.orderOut(nil)
        updateMenuState()
    }

    func showUpdateWindow<Content: View>(_ view: Content) {
        if updateWindow == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.center()

            let background = NSView(frame: window.contentView!.bounds)
            background.wantsLayer = true

            background.layer?.backgroundColor = NSColor(hex: "#131313").cgColor
            background.layer?.shadowColor = NSColor.black.cgColor
            background.layer?.shadowOpacity = 0.05
            background.layer?.shadowOffset = CGSize(width: 0, height: -2)
            background.autoresizingMask = [.width, .height]

            let hostingView = NSHostingView(rootView: view)
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            let containerView = NSView()
            containerView.addSubview(background)
            containerView.addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
                hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            window.contentView = containerView
            updateWindow = window
        }

        updateWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    func hideUpdateWindow() {
        updateWindow?.orderOut(nil)
        updateWindow = nil
    }

    func showUsageWindow() {
        if usageWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            window.title = "Wallper CPU Usage"
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear

            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.styleMask.remove(.resizable)

            let hostingView = NSHostingView(rootView: UsageGraphView(history: history))
            hostingView.appearance = NSAppearance(named: .darkAqua)
            window.contentView = hostingView

            window.center()
            window.delegate = self
            usageWindow = window
        }

        usageWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    func setupStatusBarMenu() {
        usageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateResourceStats()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(named: "StatusBarIcon") {
                image.size = NSSize(width: 22, height: 22)
                image.isTemplate = true
                button.image = image
            }
        }


        let menu = NSMenu()

        openItem = NSMenuItem(title: "Open Wallper", action: #selector(openApp), keyEquivalent: "O")
        openItem?.target = self
        menu.addItem(openItem!)

        closeItem = NSMenuItem(title: "Close Main Window", action: #selector(closeMain), keyEquivalent: "W")
        closeItem?.target = self
        menu.addItem(closeItem!)

        menu.addItem(NSMenuItem.separator())

        cpuItem = NSMenuItem(title: "CPU: ...", action: nil, keyEquivalent: "")
        ramItem = NSMenuItem(title: "RAM: ...", action: nil, keyEquivalent: "")

        menu.addItem(cpuItem!)
        menu.addItem(ramItem!)

        menu.addItem(NSMenuItem.separator())

        let graphItem = NSMenuItem(title: "Usage Graph", action: #selector(openUsage), keyEquivalent: "U")
        graphItem.target = self
        menu.addItem(graphItem)

        let quitItem = NSMenuItem(title: "Quit Wallper", action: #selector(quitApp), keyEquivalent: "Q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        updateMenuState()
    }

    private func updateMenuState() {
        openItem?.isEnabled = (mainWindow == nil)
        closeItem?.isEnabled = (mainWindow != nil)
    }

    private func updateResourceStats() {
        let cpu = cpuUsageForCurrentProcess()
        let ram = memoryUsageForCurrentProcess()

        cpuItem?.title = String(format: "CPU: %.1f%%", cpu)
        ramItem?.title = String(format: "RAM: %.1f MB", Double(ram) / 1024 / 1024)

        history.add(cpu: cpu, ramBytes: ram)
    }

    private func cpuUsageForCurrentProcess() -> Double {
        var threads: thread_act_array_t?
        var threadCount = mach_msg_type_number_t(0)

        let task = mach_task_self_
        guard task_threads(task, &threads, &threadCount) == KERN_SUCCESS,
              let threads = threads else {
            return 0
        }

        defer {
            let size = vm_size_t(UInt64(threadCount) * UInt64(MemoryLayout<thread_t>.stride))
            vm_deallocate(task, vm_address_t(UInt(bitPattern: threads)), size)
        }


        var totalUsage: Double = 0

        for i in 0..<threadCount {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let result = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(threads[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            if result == KERN_SUCCESS && (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        return totalUsage
    }

    private func memoryUsageForCurrentProcess() -> UInt64 {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }

    @objc func openApp() {
        launchMainWindow(licenseManager: licenseManager, launchManager: launchManager)
    }

    func launchMainWindow(licenseManager: LicenseManager, launchManager: LaunchManager) {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = MainContentView()
            .environmentObject(licenseManager)
            .environmentObject(launchManager)
            .frame(minWidth: 1300, minHeight: 768)

        showMainWindow(contentView)
    }

    @objc private func closeMain() {
        closeMainWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func openUsage() {
        showUsageWindow()
    }
}

extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window == mainWindow {
            mainWindow = nil
        } else if window == updateWindow {
            updateWindow = nil
        } else if window == usageWindow {
            usageWindow = nil
        }

        updateMenuState()

        if mainWindow == nil && updateWindow == nil && usageWindow == nil {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}


extension NSColor {
    convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if hex.count == 6 { hex += "FF" }

        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
        let g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
        let b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
        let a = CGFloat(hexNumber & 0x000000ff) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
