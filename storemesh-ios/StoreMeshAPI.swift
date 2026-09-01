import Foundation

struct StoreLogin: Decodable { let accessToken: String; let refreshToken: String }

struct StoreProduct: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
    let priceMinor: String
    let currency: String
    var priceText: String { "\(currency.isEmpty ? "USD" : currency) \(String(format: "%.2f", (Double(priceMinor) ?? 0) / 100))" }
}

struct StoreProductsResponse: Decodable { let products: [StoreProduct] }

struct StoreOrder: Decodable, Identifiable {
    let orderId: String
    let customerId: String
    let totalMinor: Int
    let currency: String
    let status: String
    let createdAt: String
    var id: String { orderId }
    var totalText: String { "\(currency.isEmpty ? "USD" : currency) \(String(format: "%.2f", Double(totalMinor) / 100))" }
}

struct StoreOrdersResponse: Decodable { let orders: [StoreOrder] }
struct StoreOrderLine: Encodable { let productId: String; let quantity: Int }

struct StoreMeshAPI {
    var baseURL: URL

    init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? APIConfiguration.baseURL
    }

    func login(email: String, password: String) async throws -> StoreLogin {
        try await request(path: "/api/v1/auth/login", method: "POST", body: ["email": email, "password": password])
    }

    func refresh(refreshToken: String) async throws -> StoreLogin {
        try await request(path: "/api/v1/auth/refresh", method: "POST", body: ["refreshToken": refreshToken])
    }

    func products(token: String) async throws -> [StoreProduct] {
        let response: StoreProductsResponse = try await request(path: "/api/v1/products?page_size=100&status=PRODUCT_STATUS_ACTIVE", token: token)
        return response.products
    }

    func orders(token: String) async throws -> [StoreOrder] {
        let response: StoreOrdersResponse = try await request(path: "/api/v1/orders?page_size=50", token: token)
        return response.orders
    }

    func createOrder(token: String, customerId: String, lines: [StoreOrderLine]) async throws -> StoreOrder {
        guard !lines.isEmpty else { throw URLError(.badURL) }
        let body: [String: Any] = ["customerId": customerId, "lines": lines.map { ["productId": $0.productId, "quantity": $0.quantity] }]
        return try await request(path: "/api/v1/orders", method: "POST", jsonBody: body, token: token, idempotencyKey: UUID().uuidString)
    }

    private func request<T: Decodable>(path: String, method: String = "GET", body: [String: String]? = nil, token: String? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func request<T: Decodable>(path: String, method: String, jsonBody: [String: Any], token: String, idempotencyKey: String) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIConfiguration {
    private static let defaultBaseURL = URL(string: "http://localhost:8080")!

    static var baseURL: URL {
        let launchArguments = ProcessInfo.processInfo.arguments
        if let index = launchArguments.firstIndex(of: "-storemeshApiBaseURL"),
           launchArguments.indices.contains(index + 1),
           let url = URL(string: launchArguments[index + 1]) {
            return url
        }

        if let value = ProcessInfo.processInfo.environment["STOREMESH_API_BASE_URL"],
           let url = URL(string: value) {
            return url
        }

        return defaultBaseURL
    }
}
