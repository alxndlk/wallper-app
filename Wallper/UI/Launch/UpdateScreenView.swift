import SwiftUI

struct UpdateScreenView: View {
    @ObservedObject var launchManager: LaunchManager
    @StateObject private var updater = UpdateManager()
    @StateObject private var banChecker = BanChecker()

    @State private var isVisible = false
    @State private var isFinished = false
    @State private var isChecking = true
    @State private var isUpdating = false
    @State private var isBanned = false
    @State private var isOffline = false
    @State private var updateStatus: String = "Checking for updates…"
    @State private var currentPhase: Int = 0

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        ZStack {

            if isVisible {
                backgroundGlow
            }

            VStack(spacing: 16) {
                starsIcon

                Text("Version \(currentVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)

                if isChecking || isUpdating {
                    VStack(spacing: 10) {
                        ProgressView(value: Double(currentPhase), total: 3)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 180)

                        Text(statusMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .transition(.opacity.combined(with: .scale))
                    }
                }

                Spacer()

                Text("© 2025 Wallper App")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation { isVisible = true }
            logDeviceToLambda()
            updateStatus = "Checking for updates…"
            currentPhase = 0
            updater.checkForUpdate()
        }
        .onReceive(updater.$didFinishCheck) { finished in
            guard finished else { return }

            if updater.isUpdateAvailable {
                updateStatus = "Update found – downloading…"
                isChecking = true
                isUpdating = true
                currentPhase = 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    updateStatus = "Installing update…"
                    currentPhase = 2
                    updater.startUpdate()
                }
            } else {
                currentPhase = 3
                runBanFlow()
            }
        }
    }

    private var statusMessage: String {
        if isBanned { return "Access Denied" }
        if isUpdating { return updateStatus }
        if updater.isUpdateAvailable { return "Update available – restarting…" }
        if isChecking { return updateStatus }
        if isOffline { return "Offline mode" }
        return "You're up to date!"
    }

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .blur(radius: 120)
                .offset(x: -150, y: -200)
                .scaleEffect(isFinished ? 0.7 : 1.2)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isFinished)

            Circle()
                .fill(Color.white.opacity(0.15))
                .blur(radius: 100)
                .offset(x: 100, y: 180)
                .scaleEffect(isFinished ? 0.8 : 1.1)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isFinished)
        }
    }

    private var starsIcon: some View {
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
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .scaleEffect(isVisible ? 1 : 0.85)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)
        }
    }

    private func runBanFlow() {
        banChecker.checkBanStatus { banned in
            if banned {
                isBanned = true
                isFinished = true
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { isChecking = false }

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
