import Foundation

struct VideoPublishHandler {
    static func publishVideo(
        fileURL: URL,
        meta: UploadMetadata,
        category: String,
        age: String,
        hwidid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let uuid = UUID().uuidString
        let newFileName = "\(uuid).mp4"

        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NSError(domain: "FileReadError", code: 0)))
            return
        }

        uploadToMinio(fileData: fileData, key: newFileName) { result in
            switch result {
            case .success:
                let payload: [String: Any] = [
                    "id": uuid,
                    "age": age,
                    "author": hwidid,
                    "category": category,
                    "createdAt": ISO8601DateFormatter().string(from: Date()),
                    "duration": parseDuration(meta.duration),
                    "isPublic": true,
                    "likes": 0,
                    "name": fileURL.lastPathComponent,
                    "resolution": meta.resolution,
                    "sizeMB": meta.sizeMB.replacingOccurrences(of: " MB", with: ""),
                    "status": "Pending"
                ]
                
                sendToLambda(payload: payload, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func parseDuration(_ duration: String) -> Int {
        let components = duration.split(separator: ":").map { Int($0) ?? 0 }
        guard components.count == 2 else { return 0 }
        return components[0] * 60 + components[1]
    }

    private static func uploadToMinio(fileData: Data, key: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let baseURL = Env.shared.get("LAMBDA_SIGNED_UPLOAD_URL"),
              let requestURL = URL(string: "\(baseURL)?id=\(key)") else {
            completion(.failure(NSError(domain: "InvalidSignedURLLambda", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: requestURL) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let rawString = data.flatMap({ String(data: $0, encoding: .utf8) }) {
                print("📡 Raw response data: \(rawString)")
            }

            guard let data = data,
                  let result = try? JSONDecoder().decode([String: String].self, from: data),
                  let signedURLString = result["url"],
                  let uploadURL = URL(string: signedURLString) else {
                completion(.failure(NSError(domain: "SignedURLDecodingError", code: 0)))
                return
            }

            var request = URLRequest(url: uploadURL)
            request.httpMethod = "PUT"
            request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")

            URLSession.shared.uploadTask(with: request, from: fileData) { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }.resume()
        }.resume()
    }

    private static func sendToLambda(payload: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let urlString = Env.shared.get("LAMBDA_RECORD_VIDEO_URL"),
              let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidRecordLambdaURL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let httpResponse = response as? HTTPURLResponse,
                          !(200...299).contains(httpResponse.statusCode) {
                    completion(.failure(NSError(domain: "LambdaDynamoDBWriteError", code: httpResponse.statusCode)))
                } else {
                    completion(.success(()))
                }
            }
        }.resume()
    }
}
