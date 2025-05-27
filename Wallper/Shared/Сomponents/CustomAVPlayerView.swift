import SwiftUI
import AVKit

struct CustomAVPlayerView: NSViewRepresentable {
    let player: AVPlayer
    @ObservedObject var observer: AVPlayerDisplayObserver

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = playerLayer
        view.wantsLayer = true

        observer.observe(layer: playerLayer)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
