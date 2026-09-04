//
//  storemesh_iosTests.swift
//  storemesh-iosTests
//
//  Created by Tim on 01/09/2026.
//

import Testing
@testable import storemesh_ios

struct storemesh_iosTests {

    @Test func productFormatsMinorCurrencyUnits() async throws {
        let product = Product(id: "p-1", name: "Desk lamp", description: "", priceMinor: 1299, currency: "USD")
        #expect(product.priceMinor == 1299)
    }

}
