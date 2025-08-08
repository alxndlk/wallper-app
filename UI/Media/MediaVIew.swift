import SwiftUI
import AVKit
import AppKit

struct MediaView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    @EnvironmentObject var filterStore: VideoFilterStore
    @EnvironmentObject var videoStore: VideoLibraryStore
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var scrollAnchorID = "topAnchor"
    
    private func scrollToTop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            scrollProxy?.scrollTo(scrollAnchorID, anchor: .top)
        }
    }

    @Binding var fullscreenVideo: VideoData?

    @State private var showUI = false
    @State private var lastKnownLicenseStatus: Bool = false

    @State private var totalCacheSize: Int64 = 0
    @State private var showSelect: Bool = false
    @State private var selectedItems: Set<String> = []

    @StateObject private var pagination = PaginationController<VideoData>(itemsPerPage: 21)

    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case mostLiked = "Most Liked"
    }

    @State private var selectedSort: SortOption = .newest
    @State private var gridID = UUID()
    @State private var lastVideoCount = 0

    var body: some View {
        Group {
            if licenseManager.isChecked {
                contentView
                    .opacity(showUI ? 1 : 0)
                    .blur(radius: showUI ? 0 : 10)
                    .animation(.easeOut(duration: 0.6), value: showUI)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            showUI = true
            DispatchQueue.main.async {
                applySortingAndFiltering()
                totalCacheSize = calculateCacheSize()
                lastVideoCount = videoStore.downloadedVideos.count
                scrollToTop()
            }
            filterStore.resetFilters()
        }
        .onChange(of: licenseManager.isChecked) { checked in
            if checked {
                applySortingAndFiltering()
                lastKnownLicenseStatus = licenseManager.hasLicense
            }
        }
        .onChange(of: licenseManager.hasLicense) { newStatus in
            applySortingAndFiltering()
            lastKnownLicenseStatus = newStatus
        }
        .onChange(of: selectedSort) { _ in
            applySortingAndFiltering()
            scrollToTop()
        }
        .onChange(of: filterStore.selectedFilters) { _ in
            applySortingAndFiltering()
            scrollToTop()
        }
        .onChange(of: filterStore.searchText) { _ in
            applySortingAndFiltering()
            scrollToTop()
        }
        .onChange(of: videoStore.downloadedVideos) { newVideos in
            lastVideoCount = newVideos.count
            applySortingAndFiltering()
        }
        .onChange(of: pagination.currentPage) { _ in
            scrollToTop()
        }
    }

    private func applySortingAndFiltering() {
        let filtered = filterStore.applyFilters(to: videoStore.downloadedVideos)
        let sorted = sortVideos(filtered, by: selectedSort)
        pagination.items = sorted
        pagination.goToPage(0)
        gridID = UUID()
    }

    private func sortVideos(_ videos: [VideoData], by option: SortOption) -> [VideoData] {
        switch option {
        case .newest:
            return videos.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .oldest:
            return videos.sorted { ($0.createdAt ?? "") < ($1.createdAt ?? "") }
        case .mostLiked:
            return videos.sorted { $0.likes > $1.likes }
        }
    }


    private var contentView: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 1
            let totalWidth = geometry.size.width - 32
            let minColumns = 3
            let idealColumnWidth = totalWidth / CGFloat(minColumns) - spacing
            let columns = [GridItem(.adaptive(minimum: idealColumnWidth), spacing: spacing)]

            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: 0).id("topAnchor")

                        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                            ForEach(Array(pagination.pagedItems.enumerated()), id: \.1.id) { index, item in
                                WallperCard(
                                    item: item,
                                    index: index,
                                    showTrash: showSelect,
                                    onTap: {
                                        fullscreenVideo = item
                                    },
                                    isSelected: selectedItems.contains(item.id),
                                    onSelect: {
                                        toggleSelection(for: item.id)
                                    }
                                )
                            }
                        }
                        .id(gridID)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .animation(.easeInOut(duration: 0.3), value: pagination.currentPage)
                        .padding(.bottom, 112)
                    }
                    .background(Color("#101010"))
                    .padding(.top, 8)
                    .onAppear {
                        scrollProxy = proxy
                    }
                }

                VStack(spacing: 0) {
                    HStack {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Color.white.opacity(0.8))
                                .font(.system(size: 12, weight: .semibold))

                            Text("My media")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))

                            Text(licenseManager.hasLicense ? "PRO" : "FREE")
                                .foregroundColor(.white.opacity(0.45))
                                .font(.system(size: 10, weight: .regular))
                                .baselineOffset(1)
                        }
                        .padding(.leading, 12)
                        .padding(.vertical, 8)
                        .frame(height: 46)

                        Spacer()

                        if pagination.totalPages >= 1 {
                            HStack(spacing: 12) {
                                Button(action: {
                                    showSelect.toggle()
                                    selectedItems = []
                                }) {
                                    Text(showSelect ? "Cancel" : "Select")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(formatBytes(totalCacheSize))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.white)
                                
                                Text("\(pagination.pagedItems.count + pagination.currentPage * pagination.itemsPerPage) of \(pagination.items.count) videos")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                    .font(.system(size: 10, weight: .regular))

                                Button(action: {
                                    pagination.goToPage(pagination.currentPage - 1)
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .font(.system(size: 10))
                                }
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .padding(.vertical, 5)
                                .disabled(pagination.currentPage == 0)

                                ForEach(pagination.visiblePageRange, id: \.self) { page in
                                    if page == -1 {
                                        Text("…")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 10))
                                    } else {
                                        Button(action: {
                                            pagination.goToPage(page)
                                        }) {
                                            Text("\(page + 1)")
                                                .font(.system(size: 10, weight: .regular))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(pagination.currentPage == page ? Color.blue : Color.clear)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }

                                Button(action: {
                                    pagination.goToPage(pagination.currentPage + 1)
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                        .font(.system(size: 10))
                                }
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .padding(.vertical, 5)
                                .disabled(pagination.currentPage >= pagination.totalPages - 1)

                                Menu {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Button(action: {
                                            selectedSort = option
                                        }) {
                                            Label(option.rawValue, systemImage: selectedSort == option ? "checkmark" : "")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .foregroundColor(.white)
                                        .font(.system(size: 13, weight: .medium))
                                        .frame(width: 20, height: 20)
                                        .background(Circle().fill(Color.blue))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .background(Color("#131313"))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.white.opacity(0.08)),
                        alignment: .bottom
                    )

                    Spacer()
                }
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 16) {
                    Spacer()

                    HStack {
                        manageSelectionOverlay()
                            .fixedSize()
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    private func manageSelectionOverlay() -> some View {
        ZStack {
            VStack {
                Spacer()
                HStack(spacing: 48) {
                    Text("Manage your cache by selecting videos to delete")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, 4)

                    HStack(spacing: 6) {
                        Button(action: selectAll) {
                            Text(selectedItems.count == pagination.items.count ? "Deselect All" : "Select All")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 50)
                                .foregroundColor(.white.opacity(0.9))
                                .background(Color.white.opacity(0.1))
                        }
                        .clipShape(Capsule())
                        .buttonStyle(PlainButtonStyle())

                        Button(action: deleteSelected) {
                            Text("Delete \(selectedItems.count) items")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 50)
                                .foregroundColor(.white)
                                .background(Color.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .opacity(showSelect ? 1 : 0)
                .offset(y: showSelect ? 0 : 20)
            }

            HStack {
                Spacer()
                if licenseManager.hasLicense {
                    LocalVideoDropView()
                        .padding(.horizontal, 36)
                        .opacity(showSelect ? 0 : 1)
                        .offset(y: showSelect ? 20 : 0)
                }
                FilterBottomBar()
                    .padding(.horizontal, 36)
                    .opacity(showSelect ? 0 : 1)
                    .offset(y: showSelect ? 20 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSelect)
    }


    private func calculateCacheSize() -> Int64 {
        let videoDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        let files = (try? FileManager.default.contentsOfDirectory(
            at: videoDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        )) ?? []

        var total: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }

        return total
    }


    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func toggleSelection(for id: String) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }

    private func selectAll() {
        let visibleIDs = Set(pagination.items.map { $0.id })
        if selectedItems == visibleIDs {
            selectedItems.removeAll()
        } else {
            selectedItems = visibleIDs
        }
    }

    private func deleteSelected() {
        let videoDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        for video in videoStore.downloadedVideos {
            if selectedItems.contains(video.id) {
                let filename = "\(video.id).mp4"
                let localURL = videoDir.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try? FileManager.default.removeItem(at: localURL)
                }
            }
        }

        videoStore.loadCachedVideos()
        selectedItems.removeAll()
        totalCacheSize = calculateCacheSize()
    }
}

extension Notification.Name {
    static let cacheUpdated = Notification.Name("cacheUpdated")
}
