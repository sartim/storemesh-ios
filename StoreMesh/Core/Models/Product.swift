import Foundation

struct Product: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let priceMinor: Int
    let currency: String
}

struct CartLine: Codable, Identifiable, Sendable {
    let productId: String
    var quantity: Int
    var id: String { productId }
}

struct Cart: Codable, Sendable { var lines: [CartLine] }

struct Order: Codable, Sendable {
    let id: String
    let status: String
    let totalMinor: Int
    let currency: String
    let createdAt: String
}
