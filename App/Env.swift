import Foundation

class Env {
    static let shared = Env()
    private var values: [String: String] = [:]

    private init() {}

    private let tokenParts = [""]
    private var authToken: String {
        tokenParts.joined()
    }

    func loadSyncFromLambda() {
        guard let url = URL(string: "") else {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { semaphore.signal() }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return
            }

            self.values = json
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
    }

    func get(_ key: String) -> String? {
        values[key]
    }
}
