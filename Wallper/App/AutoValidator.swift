import Foundation

class JSONValidator {
    static func validateStringArray(from data: Data) -> Bool {
        do {
            let decoded = try JSONDecoder().decode([String].self, from: data)
            return decoded.allSatisfy { isValidUUID($0) }
        } catch {
            return false
        }
    }

    static func isValidUUID(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
}
