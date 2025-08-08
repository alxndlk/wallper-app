import SwiftUI
import AppKit

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSURL, NSImage>()

    func get(forKey key: NSURL) -> NSImage? {
        cache.object(forKey: key)
    }

    func set(_ image: NSImage, forKey key: NSURL) {
        cache.setObject(image, forKey: key)
    }
}

enum CachedImagePhase {
    case success(Image)
    case failure
    case empty
}

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (CachedImagePhase) -> Content

    @State private var nsImage: NSImage?
    @State private var failed: Bool = false
    @State private var loadingStarted: Bool = false

    var body: some View {
        Group {
            if let url = url {
                if let cached = ImageCache.shared.get(forKey: url as NSURL) {
                    content(.success(Image(nsImage: cached)))
                } else if let image = nsImage {
                    content(.success(Image(nsImage: image)))
                } else if failed {
                    content(.failure)
                } else {
                    content(.empty)
                        .task {
                            if !loadingStarted {
                                loadingStarted = true
                                await loadImage(from: url)
                            }
                        }
                }
            } else {
                content(.failure)
            }
        }
    }

    private func loadImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = NSImage(data: data) {
                ImageCache.shared.set(img, forKey: url as NSURL)
                nsImage = img
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}
