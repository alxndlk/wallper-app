import SwiftUI

enum LicenseResult {
    case success
    case failure
    case deviceLimit
}

func registerHWID(licenseKey: String, hwid: String, onResult: @escaping (LicenseResult) -> Void) {
    guard let urlString = Env.shared.get("LAMBDA_REGISTER_HWID_URL"),
          let url = URL(string: urlString) else {
        onResult(.failure)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let payload: [String: String] = [
        "license_key": licenseKey,
        "hwidid": hwid
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        print("❌ Failed to encode JSON payload: \(error)")
        onResult(.failure)
        return
    }

    print("📤 Sending POST to \(url)")
    print("🔐 Payload: \(payload)")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Network error: \(error.localizedDescription)")
            onResult(.failure)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ No valid HTTP response")
            onResult(.failure)
            return
        }

        print("📡 Status Code: \(httpResponse.statusCode)")

        if let data = data, let responseText = String(data: data, encoding: .utf8) {
            print("📨 Response Body:\n\(responseText)")
        } else {
            print("⚠️ No response body")
        }

        switch httpResponse.statusCode {
        case 200:
            onResult(.success)
        case 403:
            onResult(.deviceLimit)
        default:
            onResult(.failure)
        }
    }.resume()
}
