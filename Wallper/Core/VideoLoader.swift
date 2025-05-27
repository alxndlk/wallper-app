// MARK: - VideoLoader.swift
import SwiftUI
import AVKit

class VideoLoader: ObservableObject {
    static func loadVideo(videoID: String, completion: @escaping (AVQueuePlayer?, AVPlayerItem?, URL?) -> Void) {
        guard let baseURL = Env.shared.get("S3_MODERATE_VIDEOS_PATH") else {
            return
        }
        let formats = ["mp4"]
        tryNextFormat(videoID: videoID, formats: formats, index: 0, baseURL: baseURL, completion: completion)
    }

    private static func tryNextFormat(videoID: String, formats: [String], index: Int, baseURL: String, completion: @escaping (AVQueuePlayer?, AVPlayerItem?, URL?) -> Void) {
        guard index < formats.count else {
            DispatchQueue.main.async {
                completion(nil, nil, nil)
            }
            return
        }

        let ext = formats[index]
        let urlString = "\(baseURL)\(videoID).\(ext)"
        guard let url = URL(string: urlString) else {
            tryNextFormat(videoID: videoID, formats: formats, index: index + 1, baseURL: baseURL, completion: completion)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let resp = response as? HTTPURLResponse, resp.statusCode == 200 {
                let item = AVPlayerItem(url: url)
                let queuePlayer = AVQueuePlayer()
                DispatchQueue.main.async {
                    completion(queuePlayer, item, url)
                }
            } else {
                tryNextFormat(videoID: videoID, formats: formats, index: index + 1, baseURL: baseURL, completion: completion)
            }
        }.resume()
    }
}
