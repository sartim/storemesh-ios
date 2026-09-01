import Foundation
import Security

final class SessionStore {
    private let service = "com.storemesh.ios.session"

    var accessToken: String { read(account: "accessToken") ?? "" }
    var refreshToken: String { read(account: "refreshToken") ?? "" }

    func save(_ session: StoreLogin) {
        write(session.accessToken, account: "accessToken")
        write(session.refreshToken, account: "refreshToken")
    }

    func clear() {
        delete(account: "accessToken")
        delete(account: "refreshToken")
    }

    private func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func read(account: String) -> String? {
        var item: AnyObject?
        var request = query(account: account)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        guard SecItemCopyMatching(request as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query(account: account) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query(account: account)
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private func delete(account: String) {
        SecItemDelete(query(account: account) as CFDictionary)
    }
}
