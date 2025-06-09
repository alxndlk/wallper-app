import Foundation
import AVFoundation
import Combine

class AVPlayerDisplayObserver: ObservableObject {
    @Published var isReady: Bool = false

    private var displayLink: CVDisplayLink?
    private weak var layer: AVPlayerLayer?

    func observe(layer: AVPlayerLayer) {
        self.layer = layer
        setupDisplayLink()
    }

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let displayLink = link else { return }

        self.displayLink = displayLink

        CVDisplayLinkSetOutputHandler(displayLink) { [weak self] _, _, _, _, _ in
            guard let self = self, let layer = self.layer else { return kCVReturnSuccess }

            DispatchQueue.main.async {
                let currentTime = layer.player?.currentTime().seconds ?? 0
                let visible = layer.isReadyForDisplay && currentTime > 0.1
                if self.isReady != visible {
                    self.isReady = visible
                }
            }

            return kCVReturnSuccess
        }

        CVDisplayLinkStart(displayLink)
    }

    deinit {
        displayLink.map { CVDisplayLinkStop($0) }
    }
}
