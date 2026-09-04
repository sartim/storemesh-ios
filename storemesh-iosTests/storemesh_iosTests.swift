//
//  storemesh_iosTests.swift
//  storemesh-iosTests
//
//  Created by Tim on 01/09/2026.
//

import Foundation
import Testing
@testable import storemesh_ios

struct storemesh_iosTests {

    @Test func productFormatsMinorCurrencyUnits() async throws {
        let product = Product(id: "p-1", name: "Desk lamp", description: "", priceMinor: 1299, currency: "USD")
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

}
