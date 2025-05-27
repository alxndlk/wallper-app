import SwiftUI
import AVFoundation

struct FullscreenBottomBar: View {
    @EnvironmentObject var videoLibrary: VideoLibraryStore
    var onApply: (_ screenIndex: Int?, _ applyToAll: Bool) -> Void = { _, _ in }
    var onCancel: () -> Void = {}
    @Binding var video: VideoData

    @State private var isLiked = false
    @State private var isLoopEnabled = false

    @State private var durationText: String = "~duration~"
    @State private var fileSizeText: String = "~filesize~"
    @State private var resolutionText: String = "~quality~"

    @State private var selectedScreenIndex: Int? = nil
    @State private var applyToAllScreens: Bool = false
    @State private var isShowingApplyModal = false

    private var screens: [NSScreen] {
        NSScreen.screens
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if isShowingApplyModal {
                ApplyModalView(
                    screens: screens,
                    selectedScreenIndex: $selectedScreenIndex,
                    applyToAllScreens: $applyToAllScreens,
                    onApply: {
                        isShowingApplyModal = false
                        onApply(applyToAllScreens ? nil : selectedScreenIndex, applyToAllScreens)
                    },
                    onCancel: {
                        isShowingApplyModal = false
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
                .padding(.bottom, 16)
            } else {
                mainBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut, value: isShowingApplyModal)
        .onAppear {
            isLiked = videoLibrary.isLiked(video.id)
            loadVideoMetadata()
        }
    }

    private var mainBar: some View {
        HStack(alignment: .center, spacing: 20) {
            metadataSection
            Spacer()
            actionButtons
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding()
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            let author = video.author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let category = video.category ?? ""
            let ageText = video.age != nil ? " • \(video.age!)" : ""
            let infoText = "\(category) • \(durationText) • \(fileSizeText) • \(resolutionText)\(ageText)"

            Text(author.isEmpty ? "Stored by Wallper App" : "Created by \(author)")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 12, weight: .semibold))

            Text(infoText)
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .padding(.leading, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            loopButton
            likeButton
            cancelButton
            applyButton
        }
    }

    private var loopButton: some View {
        Button(action: toggleLoop) {
            Image(systemName: isLoopEnabled ? "repeat.circle" : "repeat.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundColor(.white.opacity(isLoopEnabled ? 0.4 : 1.0))
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var likeButton: some View {
        Button(action: toggleLike) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundColor(isLiked ? .red : .white.opacity(0.7))
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Cancel")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(.white.opacity(0.9))
                .background(Color.white.opacity(0.1))
        }
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }

    private var applyButton: some View {
        Button(action: {
            let screens = NSScreen.screens
            if screens.count == 1 {
                selectedScreenIndex = 0
                applyToAllScreens = false
                onApply(selectedScreenIndex, false)
            } else {
                isShowingApplyModal = true
            }
        }) {
            Text("Set as Wallpaper")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            if isLiked {
                videoLibrary.unlikeVideo(video.id)
                Task { await videoLibrary.updateLikes(videoID: video.id, increment: -1) }
            } else {
                videoLibrary.likeVideo(video.id)
                Task { await videoLibrary.updateLikes(videoID: video.id, increment: 1) }
            }
            isLiked.toggle()
        }
    }

    private func toggleLoop() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLoopEnabled.toggle()
        }
        NotificationCenter.default.post(name: .toggleLoopPlayback, object: nil)
    }

    private func loadVideoMetadata() {
        guard let url = URL(string: video.url) else { return }
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        if duration.isFinite {
            durationText = "\(Int(duration) / 60)m \(Int(duration) % 60)s"
        }
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            resolutionText = "\(abs(Int(size.width)))x\(abs(Int(size.height)))"
        }
        if url.isFileURL, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path), let fileSize = attributes[.size] as? Int {
            fileSizeText = String(format: "%.1f MB", Double(fileSize) / 1_048_576)
        } else {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse,
                   let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
                   let fileSize = Double(contentLength) {
                    DispatchQueue.main.async {
                        fileSizeText = String(format: "%.1f MB", fileSize / 1_048_576)
                    }
                }
            }.resume()
        }
    }
}

struct ApplyModalView: View {
    let screens: [NSScreen]
    @Binding var selectedScreenIndex: Int?
    @Binding var applyToAllScreens: Bool
    var onApply: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(screens.enumerated()), id: \.0) { index, screen in
                        monitorCard(for: index, screen: screen)
                            .onTapGesture {
                                selectedScreenIndex = index
                                applyToAllScreens = false
                            }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: {
                    applyToAllScreens.toggle()
                    if applyToAllScreens {
                        selectedScreenIndex = nil
                    }
                }) {
                    Image(systemName: applyToAllScreens ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(applyToAllScreens ? .blue : .gray)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                

                Text("Apply to All Displays")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                Button(action: {
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(.white.opacity(0.9))
                        .background(Color.white.opacity(0.1))
                }
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    onApply()
                }) {
                    Text("Set as Wallpaper")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background((applyToAllScreens || selectedScreenIndex != nil) ? Color.blue : Color.gray)
                }
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())
                .disabled(!(applyToAllScreens || selectedScreenIndex != nil))
            }
            .padding(.bottom, 4)
            .padding(.top, 4)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(radius: 24)
        .fixedSize()
    }

    private func monitorCard(for index: Int, screen: NSScreen) -> some View {
        let size = screen.frame.size
        let isSelected = selectedScreenIndex == index
        let isPrimary = screen == NSScreen.main
        let cardColor = isSelected || applyToAllScreens ? Color.blue : Color.gray.opacity(0.2)

        return RoundedRectangle(cornerRadius: 10)
            .fill(cardColor)
            .frame(width: 160, height: 90)
            .overlay(
                VStack(spacing: 4) {
                    Text("Display \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("\(Int(size.width))×\(Int(size.height))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    if isPrimary {
                        Text("Current Screen")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
