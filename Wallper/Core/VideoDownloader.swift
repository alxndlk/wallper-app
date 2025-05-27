import SwiftUI

class VideoDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = VideoDownloader()

    private var completionHandler: ((URL) -> Void)?
    private var progressHandler: ((Double, Double) -> Void)?
    private var currentVideoID: String?
    private var videoStore: VideoLibraryStore?

    func download(from remoteURL: URL,
                  videoID: String,
                  store: VideoLibraryStore,
                  onProgress: @escaping (Double, Double) -> Void,
                  onComplete: @escaping (URL) -> Void) {

        let fileName = remoteURL.lastPathComponent
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localURL = cachesDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            onComplete(localURL)
            DispatchQueue.main.async {
                store.addDownloadedVideo(id: videoID)
            }

            return
        }

        self.completionHandler = onComplete
        self.progressHandler = onProgress
        self.currentVideoID = videoID
        self.videoStore = store

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        let task = session.downloadTask(with: remoteURL)
        task.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        let totalMB = Double(totalBytesExpectedToWrite) / 1024 / 1024
        let loadedMB = Double(totalBytesWritten) / 1024 / 1024
        self.progressHandler?(loadedMB, totalMB)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        guard let originalURL = downloadTask.originalRequest?.url else { return }

        let fileName = originalURL.lastPathComponent
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localURL = cachesDir.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: location, to: localURL)
            self.completionHandler?(localURL)
            if let id = self.currentVideoID {
                DispatchQueue.main.async {
                    self.videoStore?.addDownloadedVideo(id: id)
                }
            }
        } catch {
            print("Failed to move downloaded file: \(error)")
        }
    }
}
