import SwiftUI
import AVFoundation

struct LicenseWindowView: View {
    @State private var licenseKey: String = ""
    @State private var selectedTab: LicenseTab = .license
    @FocusState private var isFocused: Bool
    @State private var showContent = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showSuccess = false
    @State private var deviceLimitReached = false
    @EnvironmentObject var licenseManager: LicenseManager

    var isLicenseKeyValid: Bool {
        licenseKey.replacingOccurrences(of: "-", with: "").count == 16
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 24) {
                if showSuccess {
                    successView
                } else {
                    activationView
                }
            }
            .padding(.vertical, 80)
            .padding(.horizontal, 40)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.95)
            .animation(.easeOut(duration: 0.6), value: showContent)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.25),
                    Color.purple.opacity(0.2),
                    Color.clear
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VisualBlur()
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("License Activated")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            Text("You've unlocked unlimited access to all 4K live wallpapers, community uploads, and exclusive Pro features. Your Mac is about to get a whole lot more beautiful.")
                .font(.system(size: 13.5))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: {
                NSApp.keyWindow?.close()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.rays")
                    Text("Start Exploring")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.vertical, 80)
    }

    private var activationView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Unlock Wallper Pro")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

                Text("Access all 4K live wallpapers and premium features.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -10)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
            }

            TabSelector(selectedTab: $selectedTab)

            VStack(spacing: 12) {
                if selectedTab == .license {
                    licenseInputSection
                } else {
                    buySection
                }
            }
            .padding(.horizontal)

            Spacer()
            footerSection
        }
    }

    private var licenseInputSection: some View {
        Group {
            Text("Enter your license key below.")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 13))
                .padding(.bottom, 6)

            TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .focused($isFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .font(.system(size: 13, weight: .medium))
                .animation(.easeInOut(duration: 0.25), value: isFocused)
                .onChange(of: licenseKey) { newValue in
                    let cleaned = newValue.replacingOccurrences(of: "-", with: "")
                    let limited = String(cleaned.prefix(16))
                    var formatted = ""
                    for (i, char) in limited.enumerated() {
                        if i != 0 && i % 4 == 0 {
                            formatted += "-"
                        }
                        formatted.append(char)
                    }
                    if formatted != licenseKey {
                        licenseKey = formatted
                    }
                }

            Button(action: activateLicense) {
                Label(showSuccess ? "Activated" : "Activate", systemImage: "key.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        isLicenseKeyValid
                            ? (showSuccess ? Color.blue.opacity(0.9) : Color.blue.opacity(0.85))
                            : Color.gray.opacity(0.3)
                    )
                    .cornerRadius(10)
                    .offset(x: shakeOffset)
                    .animation(.default, value: shakeOffset)
            }
            .disabled(showSuccess)
            .buttonStyle(.plain)

            if deviceLimitReached {
                Text("⚠️ This license key is already linked to 3 devices.")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
    }

    private var buySection: some View {
        VStack(spacing: 12) {
            Text("Purchase a license and unlock all premium wallpapers.")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 13))
                .multilineTextAlignment(.center)

            Button(action: {
                if let url = URL(string: "https://wallper.app/purchase") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Visit Store", systemImage: "cart.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.85))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Text("Need a license?")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 13, weight: .medium))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 8)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: showContent)

                Link("Purchase Wallper", destination: URL(string: "https://wallper.app")!)
                    .foregroundColor(.blue)
                    .font(.system(size: 13, weight: .medium))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 8)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
            }

            Text("Each license key works on up to 3 devices.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.7), value: showContent)
        }
    }

    private func activateLicense() {
        let hwid = HWIDProvider.getHWID()
        registerHWID(licenseKey: licenseKey, hwid: hwid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSuccess = true
                        deviceLimitReached = false
                    }
                    licenseManager.checkLicense(for: hwid)

                    sendActivationMetadata(hwid: hwid, license: licenseKey)

                case .deviceLimit:
                    withAnimation {
                        deviceLimitReached = true
                    }
                    shakeInvalidKey()
                case .failure:
                    deviceLimitReached = false
                    shakeInvalidKey()
                }
            }
        }
    }

    private func sendActivationMetadata(hwid: String, license: String) {
        guard let urlString = Env.shared.get("LAMBDA_ACTIVATION_TRACK_URL"),
              let url = URL(string: urlString) else {
            return
        }

        let payload: [String: Any] = [
            "hwidid": hwid,
            "license": license,
            "license_version": true,
            "date_activated": ISO8601DateFormatter().string(from: Date())
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("❌ Failed to encode JSON payload:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Activation metadata upload failed:", error)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Activation metadata uploaded")
            } else {
                print("⚠️ Unexpected response:", response ?? "nil")
            }
        }.resume()
    }


    private func shakeInvalidKey() {
        let keyframes: [CGFloat] = [0.0, 3.15, 5.55, 6.85, 6.9, 5.77, 3.76, 1.28,
                                     -1.22, -3.29, -4.62, -5.04, -4.57, -3.37, -1.74,
                                     -0.0, 1.52, 2.58, 3.04, 2.92, 2.31, 1.41, 0.44,
                                     -0.39, -0.94, -1.15, -1.06, -0.76, -0.4, -0.11]

        for (i, value) in keyframes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.015) {
                shakeOffset = value
            }
        }
    }
}

enum LicenseTab: String, CaseIterable {
    case license = "License"
    case buy = "Buy"
}

struct TabSelector: View {
    @Binding var selectedTab: LicenseTab
    @State private var hoveredTab: LicenseTab? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(LicenseTab.allCases, id: \ .self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        Image(systemName: icon(for: tab))
                            .offset(y: hoveredTab == tab ? -1.5 : 0)
                            .scaleEffect(hoveredTab == tab ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: hoveredTab == tab)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(hoveredTab == tab ? 0.85 : 0.5))
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab || hoveredTab == tab ? Color.white.opacity(0.1) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredTab = hovering ? tab : nil
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func icon(for tab: LicenseTab) -> String {
        switch tab {
        case .license: return "key.fill"
        case .buy: return "cart.fill"
        }
    }
}

struct UpgradeView: View {
    @State private var stars: [Star] = []
    @State private var pulse = false
    @State private var gradientPulse = false
    @EnvironmentObject var licenseManager: LicenseManager


    var body: some View {
        GeometryReader { geo in
            let gradientHeight: CGFloat = 260

            ZStack {
                VStack {
                    Spacer()
                    ZStack {

                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.2),
                                Color.clear
                            ]),
                            center: .bottom,
                            startRadius: 60,
                            endRadius: 500
                        )
                        .scaleEffect(x: 2.2, y: 1.0, anchor: .bottom)
                        .scaleEffect(gradientPulse ? 1.04 : 1.0)
                        .opacity(gradientPulse ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: gradientPulse)
                        .frame(height: gradientHeight * 2)
                        .offset(y: gradientHeight / 2)
                        .allowsHitTesting(false)

                        TimelineView(.animation) { timeline in
                            let now = timeline.date.timeIntervalSinceReferenceDate
                            Canvas { context, size in
                                for star in stars {
                                    let timeFade = 0.5 + 0.5 * sin(now * 2 + star.x * 10)
                                    let opacity = star.opacity * timeFade

                                    let yOffset = CGFloat(fmod(now * star.speed, size.height))
                                    let y = size.height - yOffset
                                    let x = star.x * size.width
                                    let rect = CGRect(x: x, y: y, width: star.size, height: star.size)

                                    context.fill(
                                        Circle().path(in: rect),
                                        with: .color(Color.white.opacity(opacity))
                                    )

                                    if y < 10 {
                                        context.fill(
                                            Circle().path(in: CGRect(x: x, y: y + size.height, width: star.size, height: star.size)),
                                            with: .color(Color.white.opacity(opacity))
                                        )
                                    }
                                }
                            }
                        }
                        .frame(height: gradientHeight * 2)
                        .offset(y: gradientHeight / 2)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)

                    }
                    .frame(height: gradientHeight)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .ignoresSafeArea()
        }
        .onAppear {
            stars = (0..<100).map { _ in Star.random() }
            pulse = true
            gradientPulse = true
        }
    }

    struct Star {
        let x: CGFloat
        let speed: Double
        let size: CGFloat
        let opacity: Double

        static func random() -> Star {
            .init(
                x: CGFloat.random(in: 0...1),
                speed: Double.random(in: 10...20),
                size: CGFloat.random(in: 1.0...2.0),
                opacity: Double.random(in: 0.1...0.4)
            )
        }
    }
}

struct VisualBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
