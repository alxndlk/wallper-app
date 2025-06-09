import AVFoundation

final class VideoAssetCache {
    static let shared = VideoAssetCache()

    private let cache = NSCache<NSString, AVAsset>()

    func asset(for url: URL) -> AVAsset? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func setAsset(_ asset: AVAsset, for url: URL) {
        cache.setObject(asset, forKey: url.absoluteString as NSString)
    }
}
