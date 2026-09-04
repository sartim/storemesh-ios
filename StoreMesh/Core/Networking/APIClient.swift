import Foundation

struct APIClient: Sendable {
    var baseURL = URL(string: "http://localhost:8080/api/v1")!

    private struct GraphQLRequest: Encodable { let query: String }
    private struct GraphQLResponse<Value: Decodable>: Decodable { let data: Value?; let errors: [GraphQLError]? }
    private struct GraphQLError: Decodable { let message: String }
    private struct ProductConnection: Decodable { let products: [Product] }
    private struct ProductData: Decodable { let products: ProductConnection }
    private struct CartData: Decodable { let cart: Cart? }
    private struct OrderData: Decodable { let createOrder: Order }

    private func graphQL<Value: Decodable>(_ query: String, accessToken: String) async throws -> Value {
        var request = URLRequest(url: baseURL.appending(path: "graphql"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: query))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(GraphQLResponse<Value>.self, from: data)
        if let error = decoded.errors?.first { throw NSError(domain: "StoreMesh.GraphQL", code: 1, userInfo: [NSLocalizedDescriptionKey: error.message]) }
        guard let value = decoded.data else { throw URLError(.cannotParseResponse) }
        return value
    }

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

    func graphQLProducts(accessToken: String) async throws -> [Product] {
        let value: ProductData = try await graphQL("{ products(pageSize: 100) { products { id name description priceMinor currency } } }", accessToken: accessToken)
        return value.products.products
    }

    func graphQLCart(accessToken: String) async throws -> Cart {
        let value: CartData = try await graphQL("{ cart { lines { productId quantity } } }", accessToken: accessToken)
        return value.cart ?? Cart(lines: [])
    }

    func graphQLSaveCart(_ cart: Cart, accessToken: String) async throws -> Cart {
        let lines = cart.lines.map { "{ productId: \"\($0.productId)\", quantity: \($0.quantity) }" }.joined(separator: ",")
        let value: CartData = try await graphQL("mutation { updateCart(lines: [\(lines)]) { lines { productId quantity } } }", accessToken: accessToken)
        return value.cart ?? Cart(lines: [])
    }

    func graphQLClearCart(accessToken: String) async throws {
        let _: CartData = try await graphQL("mutation { clearCart { lines { productId quantity } } }", accessToken: accessToken)
    }

    func graphQLCreateOrder(_ cart: Cart, accessToken: String) async throws -> Order {
        let lines = cart.lines.map { "{ productId: \"\($0.productId)\", quantity: \($0.quantity) }" }.joined(separator: ",")
        let key = UUID().uuidString
        let value: OrderData = try await graphQL("mutation { createOrder(lines: [\(lines)], idempotencyKey: \"\(key)\") { id status totalMinor currency createdAt } }", accessToken: accessToken)
        return value.createOrder
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
