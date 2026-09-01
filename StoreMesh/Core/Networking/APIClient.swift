import Foundation

struct APIClient: Sendable {
    var baseURL = URL(string: "http://localhost:8080/api/v1")!

    func products() async throws -> [Product] {
        let (data, response) = try await URLSession.shared.data(from: baseURL.appending(path: "products"))
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        struct ProductResponse: Decodable { let products: [Product] }
        return try JSONDecoder().decode(ProductResponse.self, from: data).products
    }
}
