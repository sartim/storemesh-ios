import Foundation

struct APIClient: Sendable {
    var baseURL = URL(string: "http://localhost:8080/api/v1")!

    func featureFlags(accessToken: String) async -> FeatureFlags {
        do {
            var request = URLRequest(url: baseURL.appending(path: "config"))
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return .defaults }
            return try JSONDecoder().decode(FeatureFlags.self, from: data)
        } catch { return .defaults }
    }

    func products(accessToken: String? = nil) async throws -> [Product] {
        var request = URLRequest(url: baseURL.appending(path: "products"))
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        struct ProductResponse: Decodable { let products: [Product] }
        return try JSONDecoder().decode(ProductResponse.self, from: data).products
    }

    func cart(accessToken: String) async throws -> Cart {
        var request = URLRequest(url: baseURL.appending(path: "cart")); request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(Cart.self, from: data)
    }

    func saveCart(_ cart: Cart, accessToken: String) async throws -> Cart {
        var request = URLRequest(url: baseURL.appending(path: "cart")); request.httpMethod = "PUT"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization"); request.httpBody = try JSONEncoder().encode(cart)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(Cart.self, from: data)
    }

    func clearCart(accessToken: String) async throws {
        var request = URLRequest(url: baseURL.appending(path: "cart")); request.httpMethod = "DELETE"; request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }
}
