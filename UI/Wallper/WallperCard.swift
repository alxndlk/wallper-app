import SwiftUI
import AVKit
import Foundation

struct WallperCard: View {
    let item: VideoData
    let index: Int
    var showTrash: Bool = false
    let onTap: () -> Void
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil


    @State private var isHovering = false
    @State private var isReadyToShow = false
    @State private var player: AVPlayer?
    @State private var previewImage: NSImage?
    @State private var showLikes = false
    @State private var isPreviewLoading = true
    @StateObject private var playerObserver = AVPlayerDisplayObserver()
    
    @EnvironmentObject var videoLibrary: VideoLibraryStore

    static private let imageCache = NSCache<NSString, NSImage>()
    static private let cacheDirectory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("Wallper", isDirectory: true)

    static private let previewsFolder = cacheDirectory.appendingPathComponent("Previews", isDirectory: true)

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    if isPreviewLoading {
                        ZStack {
                            Color.black.opacity(0.1)
                            MiniSpinner()
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    } else if let preview = previewImage {
                        Image(nsImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }

                    if isHovering, let player = player {
                        ZStack {
                            CustomAVPlayerView(player: player, observer: playerObserver)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .opacity(playerObserver.isReady ? 1 : 0)

                            if !playerObserver.isReady {
                                MiniSpinner()
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: playerObserver.isReady)
                    }

                    Color.black.opacity(isSelected ? 0.25 : 0)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .animation(.easeInOut(duration: 0.3), value: isSelected)
                }
            }
            .aspectRatio(16/9, contentMode: .fit)

            if isHovering {
                ZStack {
                    if !playerObserver.isReady {
                        MiniSpinner()
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Preview")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 3)
                    }
                }
                .padding()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: playerObserver.isReady)
            }

            ZStack(alignment: .topTrailing) {
                GeometryReader { _ in EmptyView() }
                    .aspectRatio(16/9, contentMode: .fit)

                if showTrash {
                    Button(action: { onSelect?() }) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 1)
                                )

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(10)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        if (item.sizeMB != nil ) {
                            HStack(spacing: 6) {
                                
                                
                                let videoSize = item.sizeMB?.rounded()
                                
                                Text(String(format: "%.0f MB", videoSize!))
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 10, weight: .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.35), value: showLikes)
                            .padding(.leading, 8)
                            .padding(.bottom, 8)
                        }
                        
                        if showLikes && item.isPrivate != true {
                            HStack(spacing: 6) {
                                Image(systemName: videoLibrary.isLiked(item.id) ? "heart.fill" : "heart")
                                    .foregroundColor(videoLibrary.isLiked(item.id) ? .red : .white)
                                Text("\(videoLibrary.likes(for: item.id))")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 10, weight: .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    toggleLike()
                                }
                            )
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.35), value: showLikes)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                        }


                        else {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.circle.dotted")
                                Text("Private")
                            }
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 3)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.35), value: showLikes)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
        }
        .opacity(isReadyToShow ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isReadyToShow)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isHovering = hovering
            }

            if hovering {
                if player == nil {
                    createPlayer()
                }
                player?.play()
            } else {
                player?.pause()
                player?.seek(to: .zero)
            }
        }
        .onTapGesture {
            if !showTrash {
                withAnimation(.easeInOut(duration: 0.25)) {
                    onTap()
                }
            }
        }

        .onAppear {
            WallperCard.ensurePreviewsFolderExists()
            loadPreviewImage()
            scheduleAppear()
            showLikes = true
        }
    }
    
    private func toggleLike() {
        let liked = videoLibrary.isLiked(item.id)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if liked {
                videoLibrary.unlikeVideo(item.id)
                Task { await videoLibrary.updateLikes(videoID: item.id, increment: -1) }
            } else {
                videoLibrary.likeVideo(item.id)
                Task { await videoLibrary.updateLikes(videoID: item.id, increment: 1) }
            }
        }
    }

    private func createPlayer() {
        guard let url = URL(string: item.url) else { return }
        player = AVPlayer(url: url)
        player?.volume = 0
    }
    

    static func ensurePreviewsFolderExists() {
        let folder = Self.previewsFolder
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }

    private func loadPreviewImage() {
        guard let videoURL = URL(string: item.url) else {
            print("❌ Invalid video URL:", item.url)
            return
        }

        let cacheKey = videoURL.lastPathComponent as NSString
        let previewURL = Self.previewsFolder.appendingPathComponent("\(videoURL.lastPathComponent).jpg")

        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            self.previewImage = cachedImage
            self.isPreviewLoading = false
            return
        }

        if let data = try? Data(contentsOf: previewURL),
           let image = NSImage(data: data) {
            Self.imageCache.setObject(image, forKey: cacheKey)
            self.previewImage = image
            self.isPreviewLoading = false
            return
        }

        generateThumbnail(from: videoURL, saveTo: previewURL)
    }

    private func generateThumbnail(from videoURL: URL, saveTo previewURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 512, height: 512)

            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let middleTime = CMTime(seconds: durationSeconds / 2.0, preferredTimescale: 600)

            do {
                let cgImage = try generator.copyCGImage(at: middleTime, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: .zero)

                if let tiffData = nsImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {

                    let folderURL = previewURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

                    try jpegData.write(to: previewURL)
                }

                DispatchQueue.main.async {
                    Self.imageCache.setObject(nsImage, forKey: videoURL.lastPathComponent as NSString)
                    self.previewImage = nsImage
                    self.isPreviewLoading = false
                }
            } catch {
                print("❌ Failed to generate preview from video:", error)
            }
        }
    }


    static func cleanupOldPreviews(olderThan days: Int = 7) {
        let fileManager = FileManager.default
        let folder = Self.previewsFolder

        DispatchQueue.global(qos: .background).async {
            guard let fileURLs = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: []) else {
                return
            }

            let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

            for url in fileURLs where url.pathExtension.lowercased() == "jpg" {
                if let attributes = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modifiedDate = attributes.contentModificationDate,
                   modifiedDate < expirationDate {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
    }

    private func scheduleAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03) {
            withAnimation(.easeOut(duration: 0.45)) {
                self.isReadyToShow = true
            }
        }
    }
}
