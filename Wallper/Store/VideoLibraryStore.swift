import Foundation
import SwiftUI

struct VideoData: Identifiable, Codable, Equatable {
    let id: String
    var url: String
    var author: String?
    var author_name: String?
    var likes: Int
    var category: String?
    var age: String?
    var createdAt: String?
    var duration: Int?
    var resolution: String?
    var sizeMB: Double?
    var name: String?
    var isPrivate: Bool?
}

struct RawVideoMetadata: Codable {
    let id: String
    let likes: Int?
    let author: String?
    let author_name: String?
    let category: String?
    let createdAt: String?
    let age: String?
    let duration: Int?
    let resolution: String?
    let sizeMB: Double?
    let name: String?
}


@MainActor
class VideoLibraryStore: ObservableObject {
    @Published var wallpapersVideos: [VideoData] = []
    @Published var userGeneratedVideos: [VideoData] = []
    @Published var allVideos: [VideoData] = []
    @Published var downloadedVideos: [VideoData] = []
    @Published var likedVideos: [VideoData] = []
    @Published var isLoaded: Bool = false
    @Published private(set) var likedVideoIDs: Set<String> = []

    private static let likedKey = "liked_video_ids"

    func loadAll() async {
        isLoaded = false

        guard
            let wallpaperURL = Env.shared.get("S3_WALLPAPER_LIST"),
            let userURL = Env.shared.get("S3_USER_LIST"),
            let wallpaperBase = Env.shared.get("S3_WALLPAPER_PATH"),
            let userBase = Env.shared.get("S3_USER_VIDEOS_PATH"),
            !wallpaperURL.isEmpty,
            !userURL.isEmpty,
            !wallpaperBase.isEmpty,
            !userBase.isEmpty
        else {
            isLoaded = false
            return
        }

        do {
            async let wallpaperIDs = fetchKeys(from: wallpaperURL)
            async let userGeneratedIDs = fetchKeys(from: userURL)
            let (wallpapers, userVideos) = try await (wallpaperIDs, userGeneratedIDs)

            let allIDs = wallpapers + userVideos
            let metadata = try await fetchMetadata(for: allIDs)

            let wallpaperData: [VideoData] = wallpapers.compactMap { id in
                guard let meta = metadata[id] else { return nil }
                return VideoData(
                    id: meta.id,
                    url: "\(wallpaperBase)\(id).mp4",
                    author: meta.author,
                    author_name: meta.author_name,
                    likes: meta.likes ?? 0,
                    category: meta.category,
                    age: meta.age,
                    createdAt: meta.createdAt,
                    duration: meta.duration,
                    resolution: meta.resolution,
                    sizeMB: meta.sizeMB,
                    name: meta.name
                )
            }

            let userVideoData: [VideoData] = userVideos.compactMap { id in
                guard let meta = metadata[id] else { return nil }
                return VideoData(
                    id: meta.id,
                    url: "\(userBase)\(id).mp4",
                    author: meta.author,
                    author_name: meta.author_name,
                    likes: meta.likes ?? 0,
                    category: meta.category,
                    age: meta.age,
                    createdAt: meta.createdAt,
                    duration: meta.duration,
                    resolution: meta.resolution,
                    sizeMB: meta.sizeMB,
                    name: meta.name
                )
            }

            self.wallpapersVideos = wallpaperData
            self.userGeneratedVideos = userVideoData
            self.allVideos = wallpaperData + userVideoData
            self.loadLikedVideos()
            self.loadCachedVideos()

            for video in downloadedVideos where video.isPrivate == true {
                if !userGeneratedVideos.contains(where: { $0.id == video.id }) {
                    userGeneratedVideos.insert(video, at: 0)
                }
                if !allVideos.contains(where: { $0.id == video.id }) {
                    allVideos.insert(video, at: 0)
                }
            }

            self.isLoaded = true
        } catch {
            print("Error loading videos:", error.localizedDescription)
            self.isLoaded = false
        }
    }


    func loadLikedVideos() {
        likedVideoIDs = Self.allLikedIDs()
        likedVideos = allVideos.filter { likedVideoIDs.contains($0.id) }
    }
    
    static func allLikedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: likedKey) ?? [])
    }

    func likeVideo(_ id: String) {
        likedVideoIDs.insert(id)
        UserDefaults.standard.set(Array(likedVideoIDs), forKey: Self.likedKey)
        likedVideos = allVideos.filter { likedVideoIDs.contains($0.id) }
    }

    func unlikeVideo(_ id: String) {
        likedVideoIDs.remove(id)
        UserDefaults.standard.set(Array(likedVideoIDs), forKey: Self.likedKey)
        likedVideos = allVideos.filter { likedVideoIDs.contains($0.id) }
    }

    func isLiked(_ id: String) -> Bool {
        likedVideoIDs.contains(id)
    }

    func likes(for id: String) -> Int {
        allVideos.first(where: { $0.id == id })?.likes ?? 0
    }

    @MainActor
    func updateLikes(videoID: String, increment: Int) async {
        if let index = allVideos.firstIndex(where: { $0.id == videoID }) {
            allVideos[index].likes += increment
            objectWillChange.send()
        }

        guard let urlString = Env.shared.get("LAMBDA_LIKES_URL"),
              let url = URL(string: urlString) else {
            print("❌ Invalid or missing LAMBDA_LIKES_URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["id": videoID, "delta": increment]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to serialize JSON body: \(body)")
            return
        }

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📬 Response status code: \(httpResponse.statusCode)")
            }

            if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                print("📨 Response body:\n\(responseBody)")
            } else {
                print("⚠️ No response data received")
            }
        }.resume()
    }
    
    func addDownloadedVideo(id: String) {
        let filename = "\(id).mp4"
        let videosDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)
        let path = videosDir.appendingPathComponent(filename).path

        print("📂 Looking for file in directory: \(videosDir.path)")

        guard FileManager.default.fileExists(atPath: path) else {
            print("🚫 File not found: \(filename)")
            return
        }

        guard let video = allVideos.first(where: { $0.id == id }) else {
            print("❌ No matching video in allVideos for id: \(id)")
            return
        }

        if !downloadedVideos.contains(where: { $0.id == id }) {
            downloadedVideos.append(video)
            print("✅ Added \(id) to downloadedVideos (total: \(downloadedVideos.count))")
        }
    }

    private func fetchKeys(from urlString: String) async throws -> [String] {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let xml = String(data: data, encoding: .utf8) else { return [] }

        return xml.components(separatedBy: "<Key>")
            .dropFirst()
            .compactMap { $0.components(separatedBy: "</Key>").first }
            .filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") }
            .map { $0.replacingOccurrences(of: ".mp4", with: "").replacingOccurrences(of: ".mov", with: "") }
    }

    func loadCachedVideos() {
        let appSupportDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

        let cachedFiles = (try? FileManager.default.contentsOfDirectory(at: appSupportDir, includingPropertiesForKeys: nil)) ?? []
        let cachedMP4s = cachedFiles.filter { $0.pathExtension.lowercased() == "mp4" }

        let all = wallpapersVideos + userGeneratedVideos
        var result: [VideoData] = []

        for fileURL in cachedMP4s {
            let id = fileURL.deletingPathExtension().lastPathComponent

            if let existing = all.first(where: { $0.id == id }) {
                result.append(existing)
            } else {
                result.append(VideoData(
                    id: id,
                    url: fileURL.absoluteString,
                    author: "Local",
                    author_name: "",
                    likes: 0,
                    category: "Custom",
                    age: "0+",
                    createdAt: nil,
                    duration: nil,
                    resolution: nil,
                    sizeMB: nil,
                    name: fileURL.lastPathComponent,
                    isPrivate: true
                ))
            }
        }

        downloadedVideos = result
        
        for i in allVideos.indices {
            let id = allVideos[i].id
            if allVideos[i].isPrivate == true {
                let fileURL = appSupportDir.appendingPathComponent("\(id).mp4")
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    allVideos[i].url = fileURL.absoluteString
                }
            }
        }
    }



    
    func importLocalVideo(from url: URL) {
        let id = UUID().uuidString
        let fileExtension = url.pathExtension
        let newFilename = "\(id).\(fileExtension)"

        let appSupportDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

        let destinationURL = appSupportDir.appendingPathComponent(newFilename)

        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("✅ Copied video to \(destinationURL.lastPathComponent)")

            let sizeMB = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)
                .map { $0.doubleValue / (1024 * 1024) }

            let video = VideoData(
                id: id,
                url: destinationURL.absoluteString,
                author: "Local",
                author_name: "",
                likes: 0,
                category: "Custom",
                age: "0+",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                duration: nil,
                resolution: nil,
                sizeMB: sizeMB,
                name: url.lastPathComponent,
                isPrivate: true
            )

            if allVideos.contains(where: { $0.id == id }) {
                print("⚠️ Skipping duplicate import of \(id)")
                return
            }

            userGeneratedVideos.insert(video, at: 0)
            allVideos.insert(video, at: 0)
            downloadedVideos.insert(video, at: 0)

        } catch {
            print("❌ Failed to import video:", error.localizedDescription)
        }
    }
    
    func fixLocalVideoURLs() {
        let appSupportDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Wallper/Videos", isDirectory: true)

        for i in downloadedVideos.indices {
            let id = downloadedVideos[i].id
            let filePath = appSupportDir.appendingPathComponent("\(id).mp4")
            if FileManager.default.fileExists(atPath: filePath.path) {
                downloadedVideos[i].url = filePath.absoluteString
            } else {
                print("⚠️ File not found for downloaded video: \(id)")
            }
        }

        for i in allVideos.indices {
            let id = allVideos[i].id
            if allVideos[i].isPrivate == true {
                let filePath = appSupportDir.appendingPathComponent("\(id).mp4")
                if FileManager.default.fileExists(atPath: filePath.path) {
                    allVideos[i].url = filePath.absoluteString
                } else {
                    print("⚠️ File not found for local allVideos: \(id)")
                }
            }
        }
    }




    private func fetchMetadata(for ids: [String]) async throws -> [String: VideoData] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchBatchVideoMetadata(for: ids) { result in
                let mapped: [String: VideoData] = result.mapValues { meta in
                    VideoData(
                        id: meta.id,
                        url: "",
                        author: meta.author,
                        author_name: meta.author_name,
                        likes: meta.likes ?? 0,
                        category: meta.category,
                        age: meta.age,
                        createdAt: meta.createdAt,
                        duration: meta.duration,
                        resolution: meta.resolution,
                        sizeMB: meta.sizeMB,
                        name: meta.name
                    )
                }
                continuation.resume(returning: mapped)
            }
        }
    }
}

func fetchBatchVideoMetadata(for ids: [String], completion: @escaping ([String: RawVideoMetadata]) -> Void) {
    let chunkSize = 100
    let chunks = stride(from: 0, to: ids.count, by: chunkSize).map {
        Array(ids[$0..<min($0 + chunkSize, ids.count)])
    }

    var result: [String: RawVideoMetadata] = [:]
    let group = DispatchGroup()

    for chunk in chunks {
        group.enter()

        guard let urlString = Env.shared.get("LAMBDA_METADATA_URL"),
              let url = URL(string: urlString) else {
            print("❌ Invalid or missing LAMBDA_METADATA_URL")
            group.leave()
            continue
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(["ids": chunk])

            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { group.leave() }

                if let error = error {
                    print("❌ Network error:", error.localizedDescription)
                    return
                }

                guard let data = data else {
                    print("❌ No data received for chunk")
                    return
                }

                do {
                    
                    let decoded = try JSONDecoder().decode([RawVideoMetadata].self, from: data)

                    for item in decoded {
                        result[item.id] = item
                    }
                } catch {
                    print("❌ JSON decode error:", error.localizedDescription)
                    if let raw = String(data: data, encoding: .utf8) {
                        print("📦 Raw failed JSON:\n\(raw)")
                    }
                }
            }.resume()
        } catch {
            print("❌ Failed to encode request body:", error.localizedDescription)
            group.leave()
        }
    }

    group.notify(queue: .main) {
        completion(result)
    }
}
