import SwiftUI
import AVKit

struct FullscreenVideoView: View {
    let item: VideoData
    @Binding var fullscreenVideo: VideoData?

    @State private var player = AVPlayer()
    @State private var isReady = false
    @State private var loadingProgress: Double = 0
    @State private var fileSizeMB: Double? = nil
    @State private var loadedMB: Double = 0
    @State private var duration: String = "--"
    @State private var resolution: String = "--"
    @State private var cachedVideoURL: URL? = nil
    @StateObject private var playerObserver = AVPlayerDisplayObserver()

    @EnvironmentObject var videoLibrary: VideoLibraryStore

    var body: some View {
        ZStack {
            CustomAVPlayerView(player: player, observer: playerObserver)
                .ignoresSafeArea()
                .opacity(isReady ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: isReady)

            if !isReady {
                VStack(spacing: 16) {
                    if let total = fileSizeMB {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(width: 180, height: 6)
                                .foregroundColor(.white.opacity(0.2))

                            Capsule()
                                .frame(width: CGFloat(180 * loadingProgress), height: 4)
                                .foregroundColor(.white)
                        }
                        .animation(.easeInOut(duration: 0.2), value: loadingProgress)

                        Text(String(format: "Loading %.1f MB of %.1f MB", loadedMB, total))
                            .foregroundColor(.white)
                            .font(.caption)
                        Text(String(format: "Esc key to cancel download", loadedMB, total))
                            .foregroundColor(.white)
                            .font(.caption)
                    } else {
                        Text("Preparing video...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }

            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: isReady)

            VStack(spacing: -6) {
                Spacer().frame(height: 100)
                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                Text(Date(), style: .time)
                    .font(.system(size: 132, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 30)
                Spacer()
            }
            .animation(.easeInOut(duration: 0.4), value: isReady)

            if isReady {
                let matchingIndex = videoLibrary.allVideos.firstIndex {
                    $0.id == item.id || URL(string: $0.url)?.lastPathComponent == URL(string: item.url)?.lastPathComponent
                }

                Group {
                    if let index = matchingIndex, let localURL = cachedVideoURL {
                        FullscreenBottomBar(
                            onApply: { screenIndex, applyToAll in
                                print("Applying cached video: \(localURL.path)")
                                print("screenIndex: \(screenIndex), applyToAll: \(applyToAll)")

                                VideoWallpaperManager.shared.setVideoAsWallpaper(
                                    from: localURL,
                                    screenIndex: screenIndex,
                                    applyToAll: applyToAll
                                )
                            },
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    fullscreenVideo = nil
                                }
                            },
                            video: $videoLibrary.allVideos[index]
                        )
                    } else {
                        FullscreenBottomBar(
                            onApply: { screenIndex, applyToAll in
                                print("No matching localURL found for item \(item.id)")
                                print("screenIndex: \(screenIndex), applyToAll: \(applyToAll)")
                            },
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    fullscreenVideo = nil
                                }
                            },
                            video: .constant(item)
                        )
                    }
                }
                .environmentObject(videoLibrary)
                .frame(maxWidth: 700)
                .padding(.horizontal)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.4), value: isReady)
            }
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .zIndex(10)
        .onAppear {
            guard let remoteURL = URL(string: item.url) else { return }

            fetchFileSize(from: item.url)

            getCachedVideoURL(from: remoteURL,
                              onProgress: { loaded, total in
                DispatchQueue.main.async {
                    self.loadedMB = loaded
                    self.fileSizeMB = total
                    self.loadingProgress = total > 0 ? loaded / total : 0
                }
            }, onComplete: { localURL in
                DispatchQueue.main.async {
                    self.cachedVideoURL = localURL

                    let asset = AVAsset(url: localURL)
                    let avItem = AVPlayerItem(asset: asset)

                    let durationInSeconds = CMTimeGetSeconds(asset.duration)
                    self.duration = String(format: "%.0fs", durationInSeconds)

                    if let track = asset.tracks(withMediaType: .video).first {
                        let size = track.naturalSize.applying(track.preferredTransform)
                        self.resolution = "\(Int(abs(size.width)))x\(Int(abs(size.height)))"
                    }

                    player.replaceCurrentItem(with: avItem)
                    player.isMuted = true
                    player.actionAtItemEnd = .none

                    withAnimation(.easeInOut(duration: 0.3)) {
                        isReady = true
                    }

                    player.play()

                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: avItem,
                        queue: .main
                    ) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
                }
            })
        }
    }

    private func fetchFileSize(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse,
               let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let bytes = Double(contentLength) {
                DispatchQueue.main.async {
                    fileSizeMB = bytes / (1024 * 1024)
                }
            }
        }.resume()
    }

    private func getCachedVideoURL(
        from remoteURL: URL,
        onProgress: @escaping (Double, Double) -> Void,
        onComplete: @escaping (URL) -> Void
    ) {
        let fileName = remoteURL.lastPathComponent

        let appSupportDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

        let localURL = appSupportDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            onComplete(localURL)
        } else {
            let session = URLSession(configuration: .default, delegate: DownloadDelegate(
                destinationURL: localURL,
                videoID: item.id,
                videoStore: videoLibrary,
                onProgress: onProgress,
                onComplete: onComplete
            ), delegateQueue: .main)

            session.downloadTask(with: remoteURL).resume()
        }
    }
}

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let destinationURL: URL
    let videoID: String
    let videoStore: VideoLibraryStore
    let onProgress: (Double, Double) -> Void
    let onComplete: (URL) -> Void

    init(destinationURL: URL,
         videoID: String,
         videoStore: VideoLibraryStore,
         onProgress: @escaping (Double, Double) -> Void,
         onComplete: @escaping (URL) -> Void) {
        self.destinationURL = destinationURL
        self.videoID = videoID
        self.videoStore = videoStore
        self.onProgress = onProgress
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let totalMB = Double(totalBytesExpectedToWrite) / 1024 / 1024
        let loadedMB = Double(totalBytesWritten) / 1024 / 1024
        onProgress(loadedMB, totalMB)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.videoStore.addDownloadedVideo(id: self.videoID)
            }
            onComplete(destinationURL)
        } catch {
            print("Failed to move file: \(error)")
        }
    }
}
