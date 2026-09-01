import SwiftUI

struct CatalogView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = APIClient()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading products…")
                } else if let errorMessage {
                    ContentUnavailableView("Catalog unavailable", systemImage: "shippingbox", description: Text(errorMessage))
                } else {
                    List(products) { product in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name).font(.headline)
                            Text(product.description).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(product.currency) \(product.priceMinor / 100)").font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
            .navigationTitle("StoreMesh")
            .task { await loadProducts() }
            .refreshable { await loadProducts() }
        }
    }

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await api.products()
            errorMessage = nil
        } catch {
            errorMessage = "Start the local BFF and try again."
        }
    }
}

#Preview { CatalogView() }
