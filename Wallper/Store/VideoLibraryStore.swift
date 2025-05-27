import Foundation
import SwiftUI

struct VideoData: Identifiable, Codable, Equatable {
    let id: String
    var url: String
    var author: String?
    var likes: Int
    var category: String?
    var age: String?
    var createdAt: String?
    var duration: Int?
    var resolution: String?
    var sizeMB: Double?
    var name: String?
}

struct RawVideoMetadata: Codable {
    let id: String
    let likes: Int?
    let author: String?
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
            self.isLoaded = true
        } catch {
            print("Error loading videos:", error.localizedDescription)
            self.isLoaded = false
        }
    }


    func loadLikedVideos() {
        let likedIDs = Self.allLikedIDs()
        self.likedVideos = allVideos.filter { likedIDs.contains($0.id) }
    }

    static func allLikedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: likedKey) ?? [])
    }

    func likeVideo(_ id: String) {
        var liked = Self.allLikedIDs()
        liked.insert(id)
        UserDefaults.standard.set(Array(liked), forKey: Self.likedKey)
        loadLikedVideos()
    }

    func unlikeVideo(_ id: String) {
        var liked = Self.allLikedIDs()
        liked.remove(id)
        UserDefaults.standard.set(Array(liked), forKey: Self.likedKey)
        loadLikedVideos()
    }

    func isLiked(_ id: String) -> Bool {
        Self.allLikedIDs().contains(id)
    }
    
    func likes(for id: String) -> Int {
        allVideos.first(where: { $0.id == id })?.likes ?? 0
    }

    func updateLikes(videoID: String, increment: Int) async {
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
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let path = cacheDir.appendingPathComponent(filename).path

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
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cachedFiles = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path)) ?? []

        self.downloadedVideos = allVideos.filter {
            cachedFiles.contains("\($0.id).mp4")
        }

        let validFilenames = Set(allVideos.map { "\($0.id).mp4" })
        for file in cachedFiles where !validFilenames.contains(file) {
            let path = cacheDir.appendingPathComponent(file)
            try? FileManager.default.removeItem(at: path)
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
