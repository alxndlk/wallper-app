import SwiftUI

struct DeviceInfo: Codable, Identifiable, Equatable {
    var id: String { hwidid }

    let hwidid: String
    let device_name: String
    let device_type: String
    let macos_version: String
    let date_activated: String?

    let first_seen: String?
    let ip_address: String?
    let license: String?
    let license_version: Bool?
}

struct LicenseMapFile: Codable {
    let licenses: [String: LicenseEntry]

    struct LicenseEntry: Codable {
        let devices: [String]
    }
}

typealias UserDataFile = [DeviceInfo]

struct DevicesView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    @StateObject private var loader = DeviceLoader()
    
    @State private var showUI = false
    @State private var isUnlinking = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 12) {
                    Text("Manage Your Devices")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Here you can view every Mac connected to your license. Each device is automatically linked during activation. Easily unlink devices.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                }
                .padding(.top, 32)

                if licenseManager.isChecked {
                    devicesList
                        .padding(.top, 24)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            showUI = true
            loader.loadAllDevices()
        }
    }

    private var devicesList: some View {
          Group {
              if loader.isLoaded {
                  VStack(spacing: 12) {
                      ForEach(loader.devices) { device in
                          DeviceRow(
                              device: device,
                              isCurrent: device.hwidid == loader.hwidid,
                              isLicensed: loader.licenseStatus == .connected,
                              isUnlinking: $isUnlinking
                          ) {
                              Task {
                                  isUnlinking = true
                                  do {
                                      try await unlinkDevice(device.hwidid)
                                      await MainActor.run {
                                          loader.devices.removeAll { $0.hwidid == device.hwidid }
                                      }
                                  } catch {
                                      print("❌ Error unlinking device:", error)
                                  }
                                  isUnlinking = false
                              }
                          }
                          .transition(.opacity.combined(with: .scale))
                      }
                  }
                  .padding(.horizontal, 32)
                  .animation(.easeOut(duration: 0.4), value: loader.devices)
              } else {
                  MiniSpinner()
                      .padding(.top, 48)
              }
          }
      }
}

struct DeviceRow: View {
    let device: DeviceInfo
    let isCurrent: Bool
    let isLicensed: Bool
    @Binding var isUnlinking: Bool
    let onUnlink: () -> Void

    private var deviceIcon: String {
        switch device.device_type.lowercased() {
        case "laptop": return "laptopcomputer"
        case "imac": return "desktopcomputer"
        case "mac mini": return "macmini"
        default: return "questionmark.square.dashed"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: deviceIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 112)
                .foregroundColor(.white.opacity(0.85))

            VStack(alignment: .leading, spacing: 6) {
                Label(device.device_name, systemImage: isCurrent ? "bolt.fill" : "link" )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isCurrent ? .blue : .green)

                Text("macOS \(device.macos_version)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                if let activated = device.date_activated {
                    Text("Activated: \(formattedDate(from: activated))")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            if isLicensed && !isCurrent {
                Button(action: onUnlink) {
                    HStack(spacing: 6) {
                        if isUnlinking {
                            MiniSpinner()
                        } else {
                            Image(systemName: "xmark.circle.fill")
                        }
                        Text("Unlink")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 400)
        .padding()
        .background(.primary.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private func formattedDate(from isoString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    if let date = isoFormatter.date(from: isoString) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    let fallbackFormatter = DateFormatter()
    fallbackFormatter.dateFormat = "yyyy-MM-dd"
    if let date = fallbackFormatter.date(from: isoString) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    return isoString
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct DeviceInfoProvider {
    static var deviceName: String {
        Host.current().localizedName ?? "Unknown Device"
    }

    static var deviceType: String {
        let model = getHardwareModel()
        if model.contains("MacBook") { return "Laptop" }
        if model.contains("iMac") { return "iMac" }
        if model.contains("Macmini") { return "Mac Mini" }
        return "Unknown"
    }

    static var macosVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)"
    }

    static var dateActivated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    static func getHardwareModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
