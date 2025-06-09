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
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 14) {
                    Text("Go Beyond Basic Wallpapers")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Unlock the full Wallper experience: upload your own videos, enjoy a hand-curated 4K collection, and join a passionate creative community.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)

                    Text("One-time purchase. Lifetime access. No subscriptions.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }

                HStack(spacing: 36) {
                    FeatureColumn(icon: "sparkles.tv", text: "500+ 4K Wallpapers")
                    FeatureColumn(icon: "arrow.up.circle", text: "Upload Videos")
                    FeatureColumn(icon: "person.3", text: "Community Gallery")
                    FeatureColumn(icon: "macwindow", text: "3 Macs Usage")
                    FeatureColumn(icon: "infinity", text: "Lifetime Updates")
                }
                .frame(maxWidth: 720)

                HStack(spacing: 16) {
                    PrimaryButton(title: "Buy License", icon: "creditcard") {
                        if let url = URL(string: "https://www.wallper.app/") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    SecondaryButton(title: "Enter License", icon: "key.fill") {
                        LicenseWindowController.show(licenseManager: licenseManager)
                    }
                }

                VStack(spacing: 6) {
                    Text("✔ Secure checkout via Stripe")
                    Text("✔ Priority support included")
                    Text("✔ 14-day money-back guarantee")
                }
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

                Spacer()

                Text("One-time payment • No recurring charges • Instant access")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 32)
            .padding(.bottom, 40)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
            .shadow(color: .black.opacity(0.1), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
