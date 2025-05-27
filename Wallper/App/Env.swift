import Foundation

class Env {
    static let shared = Env()
    private var values: [String: String] = [:]

    private init() {
        loadEnvFile()
    }

    private func loadEnvFile() {
        guard let url = Bundle.main.url(forResource: "env", withExtension: "txt"),
              let content = try? String(contentsOf: url) else {
            print("❌ .env file not found in bundle")
            return
        }

        print("✅ .env file loaded from: \(url.path)")

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else {
                print("⚠️ Skipped malformed line: \(line)")
                continue
            }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)

            if value.hasPrefix("\"") && value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }

            values[key] = value
            print("📥 Loaded env: \(key) = \(value)")
        }
    }

    func get(_ key: String) -> String? {
        let value = values[key]
        if value == nil {
            print("⚠️ Missing .env key: \(key)")
        }
        return value
    }

    func debugPrintAll() {
        print("🔎 Current env values:")
        for (k, v) in values {
            print(" - \(k): \(v)")
        }
    }
}
