import SwiftUI
import AVFoundation

struct NoLicenseView: View {
    private let backgroundPlayerLayer = AVPlayerLayer()
    @EnvironmentObject var licenseManager: LicenseManager

    init() {
        if let url = Bundle.main.url(forResource: "preview", withExtension: "mp4") {
            let player = AVPlayer(url: url)
            player.isMuted = true
            player.actionAtItemEnd = .none
            player.play()

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }

            backgroundPlayerLayer.player = player
            backgroundPlayerLayer.videoGravity = .resizeAspectFill
            backgroundPlayerLayer.zPosition = -1
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text("Go Beyond Basic Wallpapers")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Unlock the full experience with Wallper Pro — one license, all features. No subscriptions. No limits.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                }

                HStack(spacing: 36) {
                    FeatureColumn(icon: "sparkles.tv", text: "500+ 4K Wallpapers")
                    FeatureColumn(icon: "arrow.up.circle", text: "Upload Videos")
                    FeatureColumn(icon: "person.3", text: "Community Gallery")
                    FeatureColumn(icon: "macwindow", text: "3 Macs Usage")
                    FeatureColumn(icon: "infinity", text: "Lifetime Updates")
                }
                .frame(maxWidth: 720)
                .padding(.top, 24)
                
                Spacer()
                

                Text("One-time purchase • Instant activation • Lifetime access")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)

            }
            .padding(.top, 32)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureColumn: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.clear
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.accentColor)
            }
            .frame(height: 36)

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 36)
        }
    }
}


struct VideoBackgroundView: NSViewRepresentable {
    let playerLayer: AVPlayerLayer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        playerLayer.frame = NSScreen.main?.frame ?? .zero
        view.wantsLayer = true
        view.layer?.addSublayer(playerLayer)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
