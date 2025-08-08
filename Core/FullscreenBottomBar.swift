import SwiftUI
import AVFoundation

struct FullscreenBottomBar: View {
    @EnvironmentObject var videoLibrary: VideoLibraryStore
    var onApply: (_ screenIndex: Int?, _ applyToAll: Bool) -> Void = { _, _ in }
    var onCancel: () -> Void = {}
    @Binding var video: VideoData

    @State private var isLiked = false

    @State private var durationText: String = "~duration~"
    @State private var fileSizeText: String = "~filesize~"
    @State private var resolutionText: String = "~quality~"

    @State private var selectedScreenIndex: Int? = nil
    @State private var applyToAllScreens: Bool = false
    @State private var isShowingApplyModal = false
    
    @State private var metadataLoaded = false


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
            let author_name = video.author_name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let category = video.category ?? ""
            let ageText = video.age?.isEmpty == false ? " • \(video.age!)" : ""

            let infoAvailable = metadataLoaded && !(
                category.isEmpty &&
                durationText == "~duration~" &&
                fileSizeText == "~filesize~" &&
                resolutionText == "~quality~"
            )

            let infoText = "\(category) • \(durationText) • \(fileSizeText) • \(resolutionText)\(ageText)"

            let authorText: String =
            {
                if video.isPrivate == true {
                    return "Wallper Local Storage"
                } else if !author_name.isEmpty {
                    return "Created by \(author_name)"
                } else {
                    return "Stored by Wallper App"
                }
            }()


            Text(authorText)
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .semibold))
            
            
            if video.isPrivate == true {
                Text("Your private content is not visible to others.")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 10))
                    .lineLimit(1)
            } else {
                Text(infoText)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 10))
                    .lineLimit(1)
            }

        }
        .padding(.leading, 4)
    }


    private var actionButtons: some View {
        HStack(spacing: 12) {
            likeButton
            cancelButton
            applyButton
        }
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

    public func toggleLike() {
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


    private func loadVideoMetadata() {

        let url: URL
        if video.url.starts(with: "file://") {
            url = URL(fileURLWithPath: video.url.replacingOccurrences(of: "file://", with: ""))
        } else if let validURL = URL(string: video.url) {
            url = validURL
        } else {
            return
        }

        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        if duration.isFinite {
            durationText = "\(Int(duration) / 60)m \(Int(duration) % 60)s"
            if video.duration == nil {
                video.duration = Int(duration)
            }
        }

        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            let resolutionString = "\(abs(Int(size.width)))x\(abs(Int(size.height)))"
            resolutionText = resolutionString
            if video.resolution == nil {
                video.resolution = resolutionString
            }
        }

        if url.isFileURL {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int {
                let sizeMB = Double(fileSize) / 1_048_576
                fileSizeText = String(format: "%.1f MB", sizeMB)
                if video.sizeMB == nil {
                    video.sizeMB = sizeMB
                }
            }
        } else {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse,
                   let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
                   let fileSize = Double(contentLength) {
                    DispatchQueue.main.async {
                        let sizeMB = fileSize / 1_048_576
                        fileSizeText = String(format: "%.1f MB", sizeMB)
                        if video.sizeMB == nil {
                            video.sizeMB = sizeMB
                        }
                    }
                }
            }.resume()
        }
        DispatchQueue.main.async {
            metadataLoaded = true
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

extension Notification.Name {
    static let changePlaybackSpeed = Notification.Name("ChangePlaybackSpeed")
}
