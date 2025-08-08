import SwiftUI
import AVKit
import UniformTypeIdentifiers
import AppKit

struct UploadMetadata {
    let name: String
    let sizeMB: String
    let resolution: String
    let format: String
    let duration: String
}

struct UserVideo: Codable, Identifiable {
    var id: String { video_id }
    let video_id: String
    let status: String
    let likes: Int
}

struct UploadView: View {
    @State private var videoURL: URL?
    @State private var uploadStatus: String = ""
    @State private var videoMeta: UploadMetadata? = nil
    @State private var uploadsLeft: Int = 5
    @State private var isDropped: Bool = false
    @State private var player: AVQueuePlayer = AVQueuePlayer()

    @State private var videoTitle: String = ""

    @State private var showRecentUploads = false
    @State private var userVideos: [UserVideo] = []

    @EnvironmentObject var licenseManager: LicenseManager

    var body: some View {
        ZStack(alignment: .top) {
            if isDropped, videoURL != nil {
                VideoBackgroundPlayer(player: player)
                    .ignoresSafeArea()
            }
            
            if !isDropped {
                Color.black.opacity(0.6).ignoresSafeArea()
            }

            ScrollView {
                if !isDropped {
                    VStack(spacing: 12) {
                        Text("Upload your own video")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Try to upload your own video in 2 clicks. Maximum file size is 500MB. Supported format: MP4")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 480)
                    }
                    .padding(.top, 32)
                }
                
                VStack(alignment: .leading, spacing: 48) {
                    Color.clear.frame(height: 12)

                    if !isDropped {
                        uploadArea
                        descriptionSection

                        if !userVideos.isEmpty, showRecentUploads {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("My Uploaded Videos")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    Text("Track the status of your submissions. Once approved, your videos will be featured for all users to discover.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 14))
                                }

                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 8) {
                                    ForEach(userVideos) { video in
                                        VideoCard(videoID: video.video_id, status: video.status, likes: video.likes)
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, isDropped ? 160 : 24)
            }

            if isDropped, let meta = videoMeta {
                VStack {
                    Spacer()
                    UploadFormView(
                        meta: meta,
                        videoTitle: $videoTitle,
                        videoURL: $videoURL,
                        isDropped: $isDropped,
                        videoMeta: $videoMeta,
                        player: $player,
                        onCompleteUpload: {
                            fetchUserVideos()
                        }
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isDropped)
        .onAppear(perform: fetchUserVideos)
    }

    private var uploadArea: some View {
        HStack(alignment: .top, spacing: 16) {
            DropArea(
                videoURL: $videoURL,
                uploadStatus: $uploadStatus,
                allowedExtensions: ["mp4"],
                maxFileSizeMB: 500,
                isDropped: $isDropped,
                player: $player
            ) { meta, _ in
                self.videoMeta = meta
                self.videoTitle = meta.name
            }
            .frame(width: 460, height: 260)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(features, id: \ .title) { feature in
                    featureItem(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
                }
            }
            .frame(height: 260)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureItem(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            Text(subtitle)
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
        .cornerRadius(16)
    }

    private func fetchUserVideos() {
        guard let urlString = Env.shared.get("LAMBDA_FETCH_USER_VIDEOS_URL"),
              let url = URL(string: urlString) else {
            return
        }

        let hwid = HWIDProvider.getHWID()
        let payload: [String: String] = ["hwidid": hwid]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Lambda error:", error ?? "Unknown error")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([UserVideo].self, from: data)
                DispatchQueue.main.async {
                    self.userVideos = decoded
                    withAnimation {
                        self.showRecentUploads = true
                    }
                }
            } catch {
                print("❌ Decoding error:", error)
                print("📦 Raw string:", String(data: data, encoding: .utf8) ?? "nil")
            }
        }.resume()
    }

    private var descriptionSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to Wallper Uploads")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Share your best 4K videos with the Wallper community. Each upload (MP4, up to 500MB) is reviewed by our team before going live in the Community Gallery.")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 14))
            }
            .frame(width: 650)
            Spacer()
        }
    }

    private var features: [(icon: String, title: String, subtitle: String)] {
        [
            ("sparkles", "4K Quality", "Upload UHD videos."),
            ("bolt", "Fast Uploads", "Up to 500MB per file."),
            ("lock.shield", "Secure Uploads", "Safty video transfer."),
            ("icloud", "Shared Library", "Reviewed gallery."),
            ("wand.and.stars", "Auto Enhancements", "Optimize your videos."),
            ("eye.slash", "Contribute & Inspire", "Join the creators.")
        ]
    }
}

struct CustomVideoPlayerView: NSViewRepresentable {
    let player: AVQueuePlayer
    let item: AVPlayerItem

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player, item: item)
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.player = player
        player.isMuted = true
        player.play()
        context.coordinator.startLooping()
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
        player.isMuted = true
        player.play()
    }

    class Coordinator {
        var looper: AVPlayerLooper?
        let player: AVQueuePlayer
        let item: AVPlayerItem

        init(player: AVQueuePlayer, item: AVPlayerItem) {
            self.player = player
            self.item = item
        }

        func startLooping() {
            looper = AVPlayerLooper(player: player, templateItem: item)
        }
    }
}

struct VideoCard: View {
    let videoID: String
    let status: String
    let likes: Int

    @State private var videoURL: URL? = nil
    @State private var isLoading = true
    @State private var player: AVQueuePlayer? = nil
    @State private var playerItem: AVPlayerItem? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let player = player, let item = playerItem {
                CustomVideoPlayerView(player: player, item: item)
                    .cornerRadius(12)
                    .aspectRatio(16/9, contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Group {
                            if isLoading {
                                MiniSpinner()
                            } else {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    )
                    .aspectRatio(16/9, contentMode: .fit)
            }

            if let label = statusLabel(for: status), let color = statusColor(for: status) {
                HStack(spacing: 6) {
                    Image(systemName: label)
                        .font(.system(size: 8, weight: .medium))

                    Text(status.capitalized)
                        .font(.system(size: 8, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Capsule())
                .padding(6)
            }

            if status == "Success" {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Label("\(likes)", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(6)
                    }
                }
            }
        }
        .onAppear(perform: loadVideo)
    }

    private func loadVideo() {
        VideoLoader.loadVideo(videoID: videoID) { loadedPlayer, loadedItem, loadedURL in
            self.player = loadedPlayer
            self.playerItem = loadedItem
            self.videoURL = loadedURL
            self.isLoading = false
        }
    }

    private func statusLabel(for status: String) -> String? {
        switch status.lowercased() {
        case "success": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "declined": return "x.circle.fill"
        default: return nil
        }
    }

    private func statusColor(for status: String) -> Color? {
        switch status.lowercased() {
        case "success": return .green
        case "pending": return .orange
        case "declined": return .red
        default: return nil
        }
    }
}

struct UploadFormView: View {
    let meta: UploadMetadata
    @Binding var videoTitle: String
    @Binding var videoURL: URL?
    @Binding var isDropped: Bool
    @Binding var videoMeta: UploadMetadata?
    @Binding var player: AVQueuePlayer
    @State private var showModal = false
    @State private var isUploading = false
    @State private var uploadError: String? = nil
    
    @State private var selectedCategory: String = ""
    @State private var selectedAge: String = ""
    @State private var selectedAuthorName: String = ""
    
    var onCompleteUpload: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(meta.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("By publishing this video, you confirm that you have the necessary rights and permissions for all content, and accept full responsibility for its nature and distribution.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 420, alignment: .leading)
                    }

                    HStack(spacing: 40) {
                        infoBlock(meta.duration, title: "Duration")
                        infoBlock(meta.resolution, title: "Resolution")
                        infoBlock(meta.format, title: "Format")
                    }

                    HStack(spacing: 12) {
                        publishButton
                        previewButton
                        cancelButton
                    }
                    .padding(.top, 8)
                }
                .padding(.leading, 32)

                Spacer()
            }
        }
        .overlay(
            ZStack {
                if showModal {
                    CustomPublishModal(
                        fileName: meta.name,
                        selectedCategory: $selectedCategory,
                        selectedAge: $selectedAge,
                        selectedAuthorName: $selectedAuthorName,
                        onPublish: {
                            guard let url = videoURL else { return }
                            
                            isUploading = true
                            VideoPublishHandler.publishVideo(
                                fileURL: url,
                                meta: meta,
                                category: selectedCategory,
                                age: selectedAge,
                                author_name: selectedAuthorName,
                                hwidid: HWIDProvider.getHWID()
                            ) { result in
                                DispatchQueue.main.async {
                                    isUploading = false
                                    withAnimation { showModal = false }
                                    
                                    switch result {
                                    case .success:
                                        isDropped = false
                                        videoURL = nil
                                        videoMeta = nil
                                        selectedCategory = ""
                                        selectedAge = ""
                                        player.pause()
                                        player.removeAllItems()
                                        onCompleteUpload()
                                    case .failure(let error):
                                        uploadError = "Failed to publish: \(error.localizedDescription)"
                                    }
                                }
                            }
                        },
                        onCancel: {
                            withAnimation { showModal = false }
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showModal)
        )
    }

    private func infoBlock(_ value: String, title: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
            Text(title)
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 12))
        }
    }

    private var publishButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showModal = true
            }
        } label: {
            Text("Publish")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 50)
                .foregroundColor(.white)
                .background(Color.blue)
        }
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }

    private var previewButton: some View {
        Button {
            if let url = videoURL {
                VideoWallpaperManager.shared.setVideoAsWallpaper(from: url, screenIndex: nil, applyToAll: true)
            }
        } label: {
            Text("Preview")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 50)
                .foregroundColor(.black)
                .background(Color.white)
        }
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }

    private var cancelButton: some View {
        Button {
            isDropped = false
            videoURL = nil
            videoMeta = nil
            videoTitle = ""
            player.pause()
            player.removeAllItems()
        } label: {
            Text("Cancel")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 50)
                .foregroundColor(.white.opacity(0.9))
                .background(Color.white.opacity(0.1))
        }
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }
}

struct DropArea: View {
    @Binding var videoURL: URL?
    @Binding var uploadStatus: String
    let allowedExtensions: [String]
    let maxFileSizeMB: Double
    @Binding var isDropped: Bool
    @Binding var player: AVQueuePlayer
    var onMetadataExtracted: ((UploadMetadata, URL) -> Void)
    
    @State private var isHovered: Bool = false
    @State private var showFilePicker: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(isHovered ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                .background(Color.white.opacity(0.03))
                .cornerRadius(20)
                .frame(maxWidth: .infinity, minHeight: 180)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

            VStack(spacing: 16) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 32))
                    .foregroundColor(.white)

                VStack(spacing: 4) {
                    Text(isHovered ? "Release to Upload" : "Drag your videos here to upload")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .animation(.easeInOut, value: isHovered)
                    
                    Text("Or click to open")
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .onTapGesture {
                openFilePicker()
            }
            .onDrop(of: [UTType.fileURL], isTargeted: $isHovered) { providers in
                if let item = providers.first {
                    _ = item.loadObject(ofClass: URL.self) { url, _ in
                        handleFileDrop(url: url)
                    }
                }
                return true
            }
        }
        .frame(width: 460, height: 260)
        .padding()
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                if let url = url {
                    handleFileDrop(url: url)
                }
            }
        }
    }

    private func handleFileDrop(url: URL?) {
        guard let url = url else { return }
        DispatchQueue.main.async {
            if allowedExtensions.contains(url.pathExtension.lowercased()) {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    let size = Double(resourceValues.fileSize ?? 0) / 1024 / 1024
                    if size <= maxFileSizeMB {
                        let asset = AVAsset(url: url)
                        let duration = CMTimeGetSeconds(asset.duration)
                        let format = url.pathExtension.uppercased()
                        let resolution = asset.tracks(withMediaType: .video).first?.naturalSize ?? .zero

                        let meta = UploadMetadata(
                            name: url.lastPathComponent,
                            sizeMB: String(format: "%.2f MB", size),
                            resolution: "\(Int(resolution.width))x\(Int(resolution.height))",
                            format: format,
                            duration: String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
                        )

                        videoURL = url
                        uploadStatus = ""
                        isDropped = true
                        onMetadataExtracted(meta, url)

                        // Настраиваем плеер
                        let item = AVPlayerItem(asset: asset)
                        player.removeAllItems()
                        player.insert(item, after: nil)
                        player.play()

                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    } else {
                        uploadStatus = "⚠️ File exceeds 500MB limit."
                    }
                } catch {
                    uploadStatus = "❌ Failed to read file size."
                }
            } else {
                uploadStatus = "⚠️ Unsupported file format."
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = allowedExtensions
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                handleFileDrop(url: url)
            }
        }
    }
}

struct FilePicker: View {
    var onFileSelected: (URL?) -> Void
    
    var body: some View {
        EmptyView()
    }
}


struct VideoBackgroundPlayer: NSViewRepresentable {
    let player: AVQueuePlayer

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspectFill
        player.isMuted = true
        context.coordinator.startLooping()
        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }

    class Coordinator {
        let player: AVQueuePlayer
        var looper: AVPlayerLooper?

        init(player: AVQueuePlayer) {
            self.player = player
        }

        func startLooping() {
            if let current = player.items().first {
                let newItem = AVPlayerItem(asset: current.asset)
                looper = AVPlayerLooper(player: player, templateItem: newItem)
            }
        }
    }
}
