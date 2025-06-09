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

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    func checkForUpdate() {
        guard let urlString = Env.shared.get("UPDATE_JSON_URL"),
              let url = URL(string: urlString) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            if let info = try? JSONDecoder().decode(UpdateInfo.self, from: data) {
                DispatchQueue.main.async {
                    self.updateInfo = info
                    self.isUpdateAvailable = info.version.compare(self.currentVersion, options: .numeric) == .orderedDescending
                    self.didFinishCheck = true
                }
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
