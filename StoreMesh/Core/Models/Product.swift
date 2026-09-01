import Foundation

struct Product: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let priceMinor: Int
    let currency: String
}
