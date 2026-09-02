import Foundation

struct FeatureFlags: Decodable, Sendable {
    let flags: [String: Bool]

    static let defaults = FeatureFlags(flags: [
        "graphql_checkout": true,
        "admin_dashboard_v2": true,
        "mobile_cart_v2": true
    ])

    func enabled(_ key: String) -> Bool { flags[key] ?? Self.defaults.flags[key] ?? false }
}
