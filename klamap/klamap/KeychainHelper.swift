import Foundation
import Security

/// Lightweight Keychain wrapper for securely storing string values (API keys, tokens).
/// Uses kSecClassGenericPassword with the app's bundle identifier as the service.
enum KeychainHelper {

    private static var service: String {
        Bundle.main.bundleIdentifier ?? "OKLAVAIR.klamap"
    }

    /// Read a string value for `key`, returns nil if absent.
    static func readString(for key: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Write or replace a string value for `key`. Returns true on success.
    @discardableResult
    static func writeString(_ value: String, for key: String) -> Bool {
        let data = value.data(using: .utf8) ?? Data()
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Try update first; if not found, add.
        let updateStatus = SecItemUpdate(q as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        if updateStatus == errSecItemNotFound {
            var addQ = q
            addQ.merge(attrs) { _, new in new }
            let addStatus = SecItemAdd(addQ as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        return false
    }

    /// Remove a stored value. No-op if absent.
    @discardableResult
    static func delete(_ key: String) -> Bool {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(q as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Convenience: returns true if a non-empty value exists for `key`.
    static func hasValue(for key: String) -> Bool {
        guard let v = readString(for: key) else { return false }
        return !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Storage keys.
enum KeychainKeys {
    static let googleMapsAPIKey = "google_maps_api_key"
    static let googleMapTilesAPIKey = "google_map_tiles_api_key"  // Photoreal 3D
}
