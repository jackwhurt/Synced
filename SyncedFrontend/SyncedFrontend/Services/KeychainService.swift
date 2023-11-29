import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()

    func save(key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String: Any]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == noErr
    }

    func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String: Any]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr, let data = dataTypeRef as? Data {
            return data
        }
        return nil
    }

    func delete(key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key ] as [String: Any]

        return SecItemDelete(query as CFDictionary) == noErr
    }
}
