import SwiftUI

struct LambdaWrapper: Decodable {
    let body: String
}

@MainActor
class VideoFilterStore: ObservableObject {
    @Published var selectedFilters: [String: String] = [:]
    @Published var dynamicFilters: [(icon: String, label: String, options: [String])] = []
    
    @Published var searchText: String = ""

    func applyFilters(to videos: [VideoData]) -> [VideoData] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return videos.filter { video in
            if !trimmedSearch.isEmpty {
                let searchFields = [
                    video.author,
                    video.author_name,
                    video.category,
                    video.resolution,
                    video.age,
                    video.name
                ]
                .compactMap { $0?.lowercased() }

                if !searchFields.contains(where: { $0.contains(trimmedSearch) }) {
                    return false
                }
            }
            
            for (key, value) in selectedFilters {
                let normalizedKey = key.lowercased()
                let normalizedValue = value.lowercased()

                switch normalizedKey {
                case "quality":
                    guard let res = video.resolution?.lowercased() else {
                        return false
                    }

                    func resolutionHeight(_ res: String) -> Int {
                        let parts = res.split(separator: "x")
                        if parts.count == 2, let height = Int(parts.last ?? "") {
                            return height
                        }
                        return 0
                    }

                    let height = resolutionHeight(res)
                    let qualityRanges: [String: Range<Int>] = [
                        "fhd": 720..<1081,
                        "2k": 1081..<1441,
                        "4k": 1441..<2161,
                        "8k": 2161..<10000
                    ]

                    guard let range = qualityRanges[normalizedValue] else {
                        return false
                    }

                    if !range.contains(height) {
                        return false
                    }

                case "duration":
                    guard let duration = video.duration else {
                        return false
                    }

                    switch normalizedValue {
                    case "short": if !(0..<16).contains(duration) { return false }
                    case "medium": if !(16..<46).contains(duration) { return false }
                    case "long": if duration < 46 { return false }
                    default: return false
                    }

                case "size":
                    guard let sizeMB = video.sizeMB else {
                        return false
                    }

                    switch normalizedValue {
                    case "small": if !(0..<10).contains(sizeMB) { return false }
                    case "medium": if !(10..<50).contains(sizeMB) { return false }
                    case "large": if sizeMB < 50 { return false }
                    default: return false
                    }

                case "age":
                    let requiredAge = Int(value.filter("0123456789".contains)) ?? 0
                    let videoAge = Int(video.age?.filter("0123456789".contains) ?? "") ?? 0
                    if videoAge < requiredAge {
                        return false
                    }

                default:
                    let mirror = Mirror(reflecting: video)
                    if let matching = mirror.children.first(where: { $0.label?.lowercased() == normalizedKey }),
                       let stringValue = matching.value as? String {
                        if stringValue.lowercased() != normalizedValue {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }

            return true
        }
    }


    func fetchDynamicFilters() async {
        guard let urlString = Env.shared.get("LAMBDA_FETCH_FILTERS_URL"),
              let url = URL(string: urlString) else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let raw = try JSONDecoder().decode([String: [String]].self, from: data)

            let durations = Set((raw["durations"] ?? []).compactMap { Double($0) }.map {
                switch $0 {
                case 0..<16: "Short"
                case 16..<46: "Medium"
                default: "Long"
                }
            })

            let sizes = Set((raw["sizes"] ?? []).compactMap { Double($0) }.map {
                switch $0 {
                case 0..<10: "Small"
                case 10..<50: "Medium"
                default: "Large"
                }
            })

            dynamicFilters = [
                ("clock", "Duration", durations.sorted()),
                ("externaldrive.fill", "Size", sizes.sorted()),
                ("arrow.up.arrow.down", "Quality", ["FHD", "2K", "4K", "8K"]),
                ("tag", "Category", raw["categories"] ?? []),
                ("person.crop.circle", "Age", raw["ages"] ?? [])
            ]
        } catch {
            print("❌ Failed to fetch dynamic filters:", error.localizedDescription)
        }
    }

    func resetFilters() {
        selectedFilters = [:]
        searchText = ""
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self))
    }
}
