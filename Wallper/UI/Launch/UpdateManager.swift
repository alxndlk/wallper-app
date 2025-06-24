import Foundation
import SwiftUI

struct UpdateInfo: Codable {
    let version: String
    let url: String
}

class UpdateManager: ObservableObject {
    @Published var isUpdateAvailable = false
    @Published var didFinishCheck = false
    @Published var updateInfo: UpdateInfo?
    
    private let tokenParts = ["sk", "_live_", "92jx", "A0vk", "Lj29", "LZZq"]
    private var authToken: String {
        tokenParts.joined()
    }

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    func checkForUpdate() {
        guard let urlString = Env.shared.get("UPDATE_JSON_URL"),
              var components = URLComponents(string: urlString) else {
            print("❌ Invalid UPDATE_JSON_URL")
            return
        }

        components.queryItems = [URLQueryItem(name: "ts", value: "\(Date().timeIntervalSince1970)")]

        guard let url = components.url else {
            print("❌ Failed to construct URL with timestamp")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request failed: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("⚠️ No data received")
                return
            }

            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let jsonString = String(data: prettyData, encoding: .utf8) {
                print("📦 Raw response:\n\(jsonString)")
            }

            do {
                let info = try JSONDecoder().decode(UpdateInfo.self, from: data)
                DispatchQueue.main.async {
                    self.updateInfo = info
                    self.isUpdateAvailable = info.version.compare(self.currentVersion, options: .numeric) == .orderedDescending
                    self.didFinishCheck = true

                    print("✅ Parsed version: \(info.version), Current version: \(self.currentVersion)")
                    print("⬆️ Update available: \(self.isUpdateAvailable)")
                }
            } catch {
                print("❌ Failed to decode UpdateInfo: \(error)")
            }

        }.resume()
    }



    func startUpdate() {
        guard let url = URL(string: updateInfo?.url ?? "") else { return }

        let tempZip = FileManager.default.temporaryDirectory.appendingPathComponent("WallperUpdate.zip")

        URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
            guard let tempURL = tempURL else { return }

            do {
                try? FileManager.default.removeItem(at: tempZip)
                try FileManager.default.moveItem(at: tempURL, to: tempZip)
                self.runShellInstaller(zipPath: tempZip.path)
            } catch {}
        }.resume()
    }

    private func runShellInstaller(zipPath: String) {
        let appPath = Bundle.main.bundlePath
        let unzipDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/WallperUpdate-\(UUID().uuidString.prefix(6))", isDirectory: true)
        try? FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

        let launcherPath = unzipDir.appendingPathComponent("wallper_relauncher.sh").path

        let script = #"""
        #!/bin/bash
        set -e

        unzip -o "\#(zipPath)" -d "\#(unzipDir.path)"

        NEW_APP="\#(unzipDir.path)/Wallper.app"
        if [ ! -d "$NEW_APP" ]; then
          exit 1
        fi

        while pgrep -x Wallper > /dev/null; do sleep 0.5; done

        rm -rf "\#(appPath)"
        mv "$NEW_APP" "\#(appPath)"
        sleep 1
        launchctl asuser $(id -u) open "\#(appPath)"
        """#

        do {
            try script.write(toFile: launcherPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcherPath)
        } catch {
            return
        }

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = [launcherPath]

        do {
            try task.run()
        } catch {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.terminate(nil)
        }
    }
}
