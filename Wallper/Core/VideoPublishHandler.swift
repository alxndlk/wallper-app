import Foundation

struct VideoPublishHandler {
    static func publishVideo(
        fileURL: URL,
        meta: UploadMetadata,
        category: String,
        age: String,
        author_name: String,
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
                    "author_name": author_name,
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
        guard let basePath = Env.shared.get("S3_MODERATE_BASE_URL"),
              let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(basePath)\(encodedKey)") else {
            print("Invalid or unencodable URL for key: \(key)")
            completion(.failure(NSError(domain: "InvalidMinIOURL", code: 0)))
            return
        }


        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: fileData) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Upload error:", error)
                    completion(.failure(error))
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Upload response status: \(httpResponse.statusCode)")
                    if (200...299).contains(httpResponse.statusCode) {
                        completion(.success(()))
                    } else {
                        let errorMsg = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        print("Upload failed with status \(httpResponse.statusCode): \(errorMsg)")
                        completion(.failure(NSError(domain: "UploadFailed", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    }
                } else {
                    print("Unknown upload error (no response)")
                    completion(.failure(NSError(domain: "UnknownUploadError", code: 0)))
                }
            }
        }

        task.resume()
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
