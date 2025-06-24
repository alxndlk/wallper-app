import SwiftUI

class DeviceLoader: ObservableObject {
    @Published var devices: [DeviceInfo] = []
    @Published var licenseStatus: LicenseStatus = .loading
    @Published var isLoaded: Bool = false

    enum LicenseStatus {
        case connected, notFound, standalone, loading
    }

    let hwidid = HWIDProvider.getHWID()

    var currentDevice: DeviceInfo {
        DeviceInfo(
            hwidid: hwidid,
            device_name: DeviceInfoProvider.deviceName,
            device_type: DeviceInfoProvider.deviceType,
            macos_version: DeviceInfoProvider.macosVersion,
            date_activated: nil,
            first_seen: nil,
            ip_address: nil,
            license: nil,
            license_version: nil
        )
    }

    func loadAllDevices() {
        Task {
            do {
                guard let urlString = Env.shared.get("LAMBDA_DEVICE_TRACK_URL"),
                      let url = URL(string: urlString) else {
                    print("Invalid URL for Lambda.")
                    await MainActor.run {
                        self.devices = [self.currentDevice]
                        self.licenseStatus = .standalone
                        self.isLoaded = true
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let payload = ["hwidid": hwidid]
                request.httpBody = try JSONEncoder().encode(payload)

                let (data, _) = try await URLSession.shared.data(for: request)

                struct Response: Decodable {
                    let status: String
                    let devices: [DeviceInfo]
                }

                let decoded = try JSONDecoder().decode(Response.self, from: data)

                await MainActor.run {
                    self.devices = decoded.devices.isEmpty ? [self.currentDevice] : decoded.devices
                    self.licenseStatus = {
                        switch decoded.status {
                        case "connected": return .connected
                        case "notFound": return .notFound
                        default: return .standalone
                        }
                    }()
                    self.isLoaded = true
                }

            } catch {
                print("Lambda error: \(error.localizedDescription)")
                await MainActor.run {
                    self.devices = [self.currentDevice]
                    self.licenseStatus = .standalone
                    self.isLoaded = true
                }
            }
        }
    }
}
