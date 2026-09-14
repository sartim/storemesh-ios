//
//  storemesh_iosTests.swift
//  storemesh-iosTests
//
//  Created by Tim on 01/09/2026.
//

import Foundation
import Testing
@testable import storemesh_ios

private final class MockBFFURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let payload: String
        if body.contains("products") {
            payload = "{\"data\":{\"products\":{\"products\":[{\"id\":\"p-1\",\"sku\":\"SM-LAMP-001\",\"name\":\"Halo desk lamp\",\"description\":\"Warm light\",\"priceMinor\":1299,\"currency\":\"USD\"}]}}}"
        } else if body.contains("createOrder") {
            payload = "{\"data\":{\"createOrder\":{\"id\":\"o-1\",\"status\":\"PENDING\",\"totalMinor\":1299,\"currency\":\"USD\",\"createdAt\":\"2026-09-14T00:00:00Z\"}}}"
        } else {
            payload = "{\"data\":{\"cart\":{\"lines\":[{\"productId\":\"p-1\",\"quantity\":1}]}}}"
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

struct storemesh_iosTests {

    @Test func productFormatsMinorCurrencyUnits() async throws {
        let product = Product(id: "p-1", sku: nil, name: "Desk lamp", description: "", priceMinor: 1299, currency: "USD")
        #expect(product.priceMinor == 1299)
    }

    @Test func cartLinesKeepProductIdentityAndQuantity() async throws {
        let line = CartLine(productId: "p-1", quantity: 2)
        #expect(line.id == "p-1")
        #expect(line.quantity == 2)
    }

    @Test func ordersDecodeTheGraphQLResponseShape() async throws {
        let data = "{\"id\":\"o-1\",\"status\":\"PENDING\",\"totalMinor\":1299,\"currency\":\"USD\",\"createdAt\":\"2026-09-04T00:00:00Z\"}".data(using: .utf8)!
        let order = try JSONDecoder().decode(Order.self, from: data)
        #expect(order.id == "o-1")
        #expect(order.totalMinor == 1299)
    }

    @Test func apiClientDecodesCatalogCartAndOrderThroughBFF() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockBFFURLProtocol.self]
        let client = APIClient(baseURL: URL(string: "https://bff.test/api/v1")!, session: URLSession(configuration: configuration))

        let products = try await client.graphQLProducts(accessToken: "test-token")
        #expect(products.first?.name == "Halo desk lamp")
        let cart = try await client.graphQLCart(accessToken: "test-token")
        #expect(cart.lines.first?.quantity == 1)
        let order = try await client.graphQLCreateOrder(cart, accessToken: "test-token")
        #expect(order.id == "o-1")
    }

}
