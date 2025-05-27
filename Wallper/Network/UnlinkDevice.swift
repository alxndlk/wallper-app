import SwiftUI

struct UnlinkRequest: Codable {
    let hwidid: String
}

func unlinkDevice(_ hwidid: String) async throws {
    guard let urlString = Env.shared.get("LAMBDA_UNLINK_DEVICE_URL"),
          let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(UnlinkRequest(hwidid: hwidid))

    let (data, response) = try await URLSession.shared.data(for: request)

    if let httpResponse = response as? HTTPURLResponse {
        print("📡 Status code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "Empty body"
            print("❌ Response body:", body)
            throw URLError(.badServerResponse)
        }
    }
}
