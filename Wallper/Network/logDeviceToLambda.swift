import SwiftUI

func logDeviceToLambda() {
    guard let urlString = Env.shared.get("LAMBDA_DEVICE_LOG_URL"),
          let url = URL(string: urlString) else {
        return
    }

    let hwidid = HWIDProvider.getHWID()
    let payload: [String: Any] = [
        "hwidid": hwidid,
        "device_name": DeviceInfoProvider.deviceName,
        "device_type": DeviceInfoProvider.deviceType,
        "macos_version": DeviceInfoProvider.macosVersion
    ]

    guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
        print("Failed to encode payload")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Device log error:", error)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("Device Response status:", httpResponse.statusCode)
        }

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) {
            print("Device log result:", json)
        } else {
            print("No response data or failed to parse JSON")
        }
    }.resume()
}
