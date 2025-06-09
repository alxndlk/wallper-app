import Foundation
import Combine

class BanChecker: ObservableObject {
    @Published var isBanned = false
    private var hwid: String = "unknown"
    @Published private var publicIP: String?

    private var cancellables = Set<AnyCancellable>()
    private var isChecking = false
    private var hasPendingCheck = false
    private var completionHandler: ((Bool) -> Void)?
    private var ipTimeoutTask: DispatchWorkItem?

    init() {
        self.hwid = HWIDProvider.getHWID()
        observeIP()
        fetchPublicIP()
    }

    private func observeIP() {
        $publicIP
            .compactMap { $0 }
            .sink { [weak self] ip in
                guard let self = self, self.hasPendingCheck else { return }
                self.hasPendingCheck = false
                self.ipTimeoutTask?.cancel()
                self.performBanCheck(ip: ip)
            }
            .store(in: &cancellables)
    }

    func checkBanStatus(completion: @escaping (Bool) -> Void) {
        guard !isChecking else { return }
        isChecking = true
        self.completionHandler = completion

        if let ip = publicIP {
            performBanCheck(ip: ip)
        } else {
            hasPendingCheck = true

            let timeout = DispatchWorkItem { [weak self] in
                guard let self = self, self.hasPendingCheck else { return }
                self.hasPendingCheck = false
                self.performBanCheck(ip: "")
            }

            ipTimeoutTask = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: timeout)
        }
    }

    private func performBanCheck(ip: String) {
        guard let urlString = Env.shared.get("LAMBDA_CHECK_BAN_URL"),
              let url = URL(string: urlString) else {
            isChecking = false
            return
        }


        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["hwid": hwid, "ip": ip]
        guard let jsonData = try? JSONEncoder().encode(body) else {
            isChecking = false
            return
        }

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isChecking = false

                if let error = error {
                    self.completionHandler?(false)
                    return
                }

                guard let data = data else {
                    self.completionHandler?(false)
                    return
                }

                if let result = try? JSONDecoder().decode([String: Bool].self, from: data),
                   let banned = result["banned"] {
                    self.isBanned = banned
                    self.completionHandler?(banned)
                } else {
                    self.completionHandler?(false)
                }
            }
        }.resume()
    }

    private func fetchPublicIP() {
        guard let url = URL(string: "https://api.ipify.org") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let ip = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.publicIP = ip
            }
        }.resume()
    }
}
