import Foundation

class LicenseManager: ObservableObject {
    @Published var hasLicense: Bool = false
    @Published var isChecked: Bool = false
    @Published var licenseKey: String? = nil

    func checkLicense(for hwidid: String, completion: (() -> Void)? = nil) {
        guard let urlString = Env.shared.get("LAMBDA_LICENSE_CHECK_URL"),
              let url = URL(string: urlString) else {
            updateState(found: false, licenseKey: nil, completion: completion)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["hwidid": hwidid]
        guard let jsonData = try? JSONEncoder().encode(body) else {
            print("Failed to encode JSON body")
            updateState(found: false, licenseKey: nil, completion: completion)
            return
        }

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("[LicenseManager] Network error:", error.localizedDescription)
                self.updateState(found: false, licenseKey: nil, completion: completion)
                return
            }

            guard let data = data,
                  let response = try? JSONDecoder().decode(LicenseResponse.self, from: data) else {
                print("Failed to decode response")
                self.updateState(found: false, licenseKey: nil, completion: completion)
                return
            }

            self.updateState(found: response.valid, licenseKey: response.key, completion: completion)
        }.resume()
    }

    private func updateState(found: Bool, licenseKey: String?, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            self.hasLicense = found
            self.licenseKey = licenseKey
            self.isChecked = true
            print("[LicenseManager] Updated — hasLicense: \(found), key: \(licenseKey ?? "nil")")
            completion?()
        }
    }

    struct LicenseResponse: Decodable {
        let valid: Bool
        let key: String?
    }
}
