import AppKit
import AVKit

class VideoWallpaperManager: NSObject {
    static let shared = VideoWallpaperManager()

    private var players: [String: AVQueuePlayer] = [:]
    private var windows: [String: NSWindow] = [:]
    private var loopers: [String: AVPlayerLooper] = [:]

    private override init() {
        super.init()
    }

    func setVideoAsWallpaper(
        from url: URL,
        screenIndex: Int?,
        applyToAll: Bool = true,
        muteSecondaryScreens: Bool = true
    ) {
        stopCurrentWallpaper(screenIndex: screenIndex)

        let screens = NSScreen.screens
        for (index, screen) in screens.enumerated() {
            if !applyToAll, index != screenIndex { continue }

            let screenID = screen.deviceIdentifier
            let isMain = screen == NSScreen.main
            let frame = screen.frame

            let window = NSWindow(
                contentRect: CGRect(origin: .zero, size: frame.size),
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.setFrame(frame, display: true)
            window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) - 1)
            window.ignoresMouseEvents = true
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            window.collectionBehavior = [
                .canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle
            ]

            let contentView = NSView(frame: frame)
            contentView.wantsLayer = true
            window.contentView = contentView

            let item = AVPlayerItem(url: url)
            item.preferredForwardBufferDuration = 0

            let player = AVQueuePlayer()
            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            let looper = AVPlayerLooper(player: player, templateItem: item)

            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = frame
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.needsDisplayOnBoundsChange = true

            contentView.layer = playerLayer

            players[screenID] = player
            loopers[screenID] = looper
            windows[screenID] = window
            
            saveAppliedWallpaper(url: url, screenIndex: index)

            window.makeKeyAndOrderFront(nil)
            window.alphaValue = 1

            if let contentView = window.contentView {
                animateReveal(fromCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), in: contentView)
            }

            contentView.layoutSubtreeIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                player.play()
            }
        }
    }
    
    private func saveAppliedWallpaper(url: URL, screenIndex: Int) {
        let key = "LastAppliedWallpapers"
        var current = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []

        let entry: [String: Any] = [
            "screenIndex": screenIndex,
            "url": url.absoluteString,
            "appliedAt": Date().timeIntervalSince1970
        ]

        current.removeAll { $0["screenIndex"] as? Int == screenIndex }
        current.append(entry)

        UserDefaults.standard.set(current, forKey: key)
    }
    
    private func animateReveal(fromCenter center: CGPoint, in view: NSView) {
        let startPath = NSBezierPath(ovalIn: CGRect(origin: center, size: .zero))
        let maxDimension = max(view.bounds.width, view.bounds.height) * 1.5
        let endPath = NSBezierPath(ovalIn: CGRect(
            x: center.x - maxDimension,
            y: center.y - maxDimension,
            width: maxDimension * 2,
            height: maxDimension * 2
        ))

        let maskLayer = CAShapeLayer()
        maskLayer.path = endPath.cgPath
        view.layer?.mask = maskLayer

        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = startPath.cgPath
        animation.toValue = endPath.cgPath
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        maskLayer.add(animation, forKey: "reveal")
        maskLayer.path = endPath.cgPath

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            view.layer?.mask = nil
        }
    }

    func stopCurrentWallpaper(screenIndex: Int? = nil) {
        if let index = screenIndex, NSScreen.screens.indices.contains(index) {
            let screen = NSScreen.screens[index]
            let screenID = screen.deviceIdentifier

            players[screenID]?.pause()
            windows[screenID]?.orderOut(nil)

            players.removeValue(forKey: screenID)
            windows.removeValue(forKey: screenID)
            loopers.removeValue(forKey: screenID)

        } else {
            players.values.forEach { $0.pause() }
            windows.values.forEach { $0.orderOut(nil) }

            players.removeAll()
            windows.removeAll()
            loopers.removeAll()
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "status",
           let item = object as? AVPlayerItem {
            switch item.status {
            case .readyToPlay:
                print("AVPlayerItem ready to play")
            case .failed:
                print("AVPlayerItem failed: \(String(describing: item.error))")
            default:
                break
            }
            item.removeObserver(self, forKeyPath: "status")
        }
    }
}



extension NSScreen {
    var deviceIdentifier: String {
        if let screenNumber = deviceDescription[.init("NSScreenNumber")] as? NSNumber {
            return screenNumber.stringValue
        }
        return UUID().uuidString
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            @unknown default: break
            }
        }
        points.deallocate()
        return path
    }
}
