import SwiftUI
import AVFoundation

struct SettingsView: View {
    private let backgroundPlayerLayer = AVPlayerLayer()

    @AppStorage("restoreLastWallpapers") private var restoreLastWallpapers: Bool = false
    @AppStorage("wallpaperOfDayID") private var wallpaperOfDayID: String = ""
    @AppStorage("wallpaperOfDayDate") private var wallpaperOfDayDate: String = ""

    @State private var cacheSize: String = SettingsMetrics.currentCacheSize()
    @State private var cacheUsageBytes: Double = SettingsMetrics.currentCacheSizeInBytes()
    @State private var showCleared = false
    @State private var licenseUnlinked = false
    @EnvironmentObject var videoStore: VideoLibraryStore
    
    @State private var isUnlinking = false
    
    @EnvironmentObject var licenseManager: LicenseManager
    @State private var isWallpaperLoading = true


    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                headerSection
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 32)

                Group() {
                    toggleRow(
                        title: "Restore wallpapers on launch",
                        description: "Automatically reapplies the last wallpapers when Wallper starts.",
                        isOn: $restoreLastWallpapers
                    )

                    cacheUsageSection

                    if licenseManager.isChecked && licenseManager.hasLicense {
                        wallpaperOfDaySection
                        unlinkLicenseSection
                    }
                }
                .frame(width: 480)
                .padding(.top, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }


    var headerSection: some View {
        VStack(spacing: 12) {
            Text("Wallper Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("Customize how your desktop wallpapers behave, when they appear, and how they get managed.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
        }
    }

    var cacheUsageSection: some View {
        let bars = Array(repeating: Color.green, count: 2) + Array(repeating: Color.orange, count: 4) + Array(repeating: Color.red, count: 6)
        let maxBytes: Double = 6_000_000_000
        let currentRatio = min(cacheUsageBytes / maxBytes, 1.0)
        let filledCount = Int(currentRatio * 12)

        return VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disk Cache Usage")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .medium))
                    Text("Currently used: \(cacheSize)")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 12))
                }
                Spacer()
            }

            HStack(spacing: 4) {
                ForEach(0..<6) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < filledCount ? bars[i] : Color.white.opacity(0.1))
                        .frame(height: 4)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 4)
            
            HStack(spacing: 8) {
                Image(systemName: "wand.and.rays.inverse")
                    .foregroundColor(.white)
                    .frame(width: 14)

                Text("Clear Disk Cache")
                    .foregroundColor(.white)
                    .font(.system(size: 11, weight: .regular))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
            )
            .shadow(color: .primary.opacity(0.06), radius: 5)
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                let videoDir = FileManager.default
                    .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                    .first!
                    .appendingPathComponent("Wallper/Videos", isDirectory: true)

                for video in videoStore.downloadedVideos {
                    let filename = "\(video.id).mp4"
                    let localURL = videoDir.appendingPathComponent(filename)
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try? FileManager.default.removeItem(at: localURL)
                    }
                }

                videoStore.loadCachedVideos()
                cacheSize = SettingsMetrics.currentCacheSize()
                cacheUsageBytes = SettingsMetrics.currentCacheSizeInBytes()
                showCleared = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCleared = false
                }
            }
        }
        .padding()
        .background(.primary.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }

    var wallpaperOfDaySection: some View {
        let wallpaperVideo = updateWallpaperOfDay(from: videoStore.allVideos)
        let videoURL = wallpaperVideo.flatMap { URL(string: $0.url) }

        return ZStack(alignment: .bottom) {
            Group {
                if let url = videoURL {
                    WallpaperPreviewPlayerView(url: url)
                        .onAppear {
                            isWallpaperLoading = false
                        }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(width: 480, height: 270)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .cornerRadius(12)
            )

            if isWallpaperLoading {
                MiniSpinner()
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallpaper of the Day")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .medium))
                    Text("We found a stunning new wallpaper for you today!")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 4)
                    HStack(spacing: 8) {
                        Image(systemName: "cloud.sun")
                            .foregroundColor(.white)
                            .frame(width: 14)

                        Text("Set As Wallpaper")
                            .foregroundColor(.white)
                            .font(.system(size: 11, weight: .regular))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                    )
                    .shadow(color: .primary.opacity(0.06), radius: 5)
                    .contentShape(Rectangle())
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        if let url = videoURL {
                            VideoWallpaperManager.shared.setVideoAsWallpaper(from: url, screenIndex: nil, applyToAll: true)
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear {
            isWallpaperLoading = (videoURL == nil)
        }
    }

    
    func updateWallpaperOfDay(from allVideos: [VideoData]) -> VideoData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        if wallpaperOfDayDate != todayString || !allVideos.contains(where: { $0.id == wallpaperOfDayID }) {
            if let random = allVideos.randomElement() {
                wallpaperOfDayID = random.id
                wallpaperOfDayDate = todayString
                return random
            }
            return nil
        } else {
            return allVideos.first(where: { $0.id == wallpaperOfDayID })
        }
    }

    var unlinkLicenseSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlink License")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .medium))
                    Text("This will remove the current license from this device.")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 12))
                        .padding(.bottom, 4)
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .frame(width: 14)
                        
                        Text(isUnlinking ? "Unlinking..." : "Unlink Current Device")
                            .foregroundColor(.white)
                            .font(.system(size: 11, weight: .regular))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)
                    )
                    .shadow(color: .primary.opacity(0.06), radius: 5)
                    .contentShape(Rectangle())
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        licenseUnlinked = true
                        let hwidid = HWIDProvider.getHWID()
                        isUnlinking = true
                        
                        Task {
                            do {
                                try await unlinkDevice(hwidid)
                                licenseManager.hasLicense = false
                                
                            } catch {
                                print("❌ Failed to unlink:", error)
                            }
                            isUnlinking = false
                        }
                    }
                }
            }
        }
        .padding()
        .background(.primary.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }

    private func toggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { isOn.wrappedValue.toggle() }) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding()
        .background(.primary.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }
}

struct SettingsMetrics {
    static func currentCacheSizeInBytes() -> Double {
        let videoDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        let files = (try? FileManager.default.contentsOfDirectory(at: videoDir, includingPropertiesForKeys: [.fileSizeKey], options: [])) ?? []
        
        return files.reduce(0.0) { result, url in
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { result + Double($0) } ?? result
        }
    }

    static func currentCacheSize() -> String {
        return String(format: "%.1f MB", currentCacheSizeInBytes() / 1_048_576)
    }

    static func clearCache() {
        let videoDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        let files = (try? FileManager.default.contentsOfDirectory(at: videoDir, includingPropertiesForKeys: [.fileSizeKey], options: [])) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

}

struct WallpaperPreviewPlayerView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.play()

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect(x: 0, y: 0, width: 480, height: 270)

        view.layer = CALayer()
        view.layer?.addSublayer(playerLayer)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
