import SwiftUI

struct CatalogView: View {
    let accessToken: String
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cart = Cart(lines: [])
    @State private var showingCart = false

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
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showingCart = true } label: { Label("Cart (\(cart.lines.reduce(0) { $0 + $1.quantity }))", systemImage: "cart") } } }
            .sheet(isPresented: $showingCart) { CartView(products: products, cart: $cart, onChange: saveCart, onClear: clearCart) }
            .task { await loadProducts(); await loadCart() }
            .refreshable { await loadProducts() }
        }
    }

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await api.products(accessToken: accessToken)
            errorMessage = nil
        } catch {
            errorMessage = "Start the local BFF and try again."
        }
    }

    private func loadCart() async { do { cart = try await api.cart(accessToken: accessToken) } catch { /* Empty cart is a valid first-run state. */ } }
    private func saveCart(_ next: Cart) async { do { cart = try await api.saveCart(next, accessToken: accessToken) } catch { errorMessage = "Unable to save your cart." } }
    private func clearCart() async { do { try await api.clearCart(accessToken: accessToken); cart = Cart(lines: []) } catch { errorMessage = "Unable to clear your cart." } }
}

#Preview { CatalogView() }
