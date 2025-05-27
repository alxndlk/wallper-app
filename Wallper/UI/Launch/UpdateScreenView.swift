import SwiftUI

struct UpdateScreenView: View {
    @ObservedObject var launchManager: LaunchManager

    @State private var isVisible = false
    @State private var isFinished = false
    @State private var isOffline = false
    @State private var isBanned = false
    @State private var isChecking = true
    @State private var opacity: Double = 1
    @StateObject private var banChecker = BanChecker()

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            if isVisible {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .blur(radius: 120)
                    .offset(x: -150, y: -200)
                    .scaleEffect(isFinished ? 0.7 : 1.2)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isFinished)

                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .blur(radius: 100)
                    .offset(x: 100, y: 180)
                    .scaleEffect(isFinished ? 0.8 : 1.1)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isFinished)
            }

            VStack(spacing: 32) {
                ZStack {
                    ForEach(0..<12) { i in
                        let angle = Double(i) / 12 * 2 * .pi
                        let distance: CGFloat = 60
                        let delay = Double(i) * 0.05
                        AnimatedStar(angle: angle, distance: distance, delay: delay)
                    }

                    Image(systemName: "sparkles")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .scaleEffect(isVisible ? 1 : 0.85)
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)
                }

                Text("Version \(currentVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)

                HStack(spacing: 12) {
                    if isChecking {
                        MiniSpinner()
                    }

                    Text(
                        isBanned ? "Access Denied" :
                        isChecking ? "Checking for updates…" :
                        isOffline ? "Offline mode" :
                        "You're up to date!"
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .scale))
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)

                Spacer()

                Text("\u{00a9} 2025 Wallper App")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            logDeviceToLambda()
            withAnimation {
                isVisible = true
            }

            banChecker.checkBanStatus { banned in
                if banned {
                    isBanned = true
                    isFinished = true
                    print("☠️ Banned.")
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        isChecking = false
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isFinished = true
                            launchManager.isReady = true
                        }
                    }
                }
            }
        }
    }
}
