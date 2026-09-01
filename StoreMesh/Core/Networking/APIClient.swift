import Foundation

struct APIClient: Sendable {
    var baseURL = URL(string: "http://localhost:8080/api/v1")!

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
}
