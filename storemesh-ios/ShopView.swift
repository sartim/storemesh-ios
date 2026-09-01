import SwiftUI

struct ShopView: View {
    let token: String
    var onLogout: () -> Void
    @State private var products: [StoreProduct] = []
    @State private var search = ""
    @State private var showMenu = false
    @State private var showOrders = false
    @State private var selectedProduct: StoreProduct?
    @State private var error = ""

    private var filtered: [StoreProduct] { products.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.description.localizedCaseInsensitiveContains(search) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if showOrders { OrdersView(token: token) }
                    else {
                        Text("Find your next favourite").font(.largeTitle.bold())
                        Text("Curated picks, everyday deals.").foregroundStyle(.secondary)
                        TextField("Search products", text: $search).textFieldStyle(.roundedBorder)
                        if !error.isEmpty { Text(error).foregroundStyle(.red) }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) { ForEach(filtered) { product in ProductCard(product: product) { selectedProduct = product } } }
                    }
                }.padding()
            }
            .navigationTitle(showOrders ? "My orders" : "Shop")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { showMenu = true } label: { Label("Menu", systemImage: "line.3.horizontal") } }
                ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bag") }
            }
            .sheet(isPresented: $showMenu) { MenuView(onOrders: { showOrders = true }, onShop: { showOrders = false }, onLogout: onLogout) }
            .sheet(item: $selectedProduct) { ProductDetailView(product: $0) }
            .task { await loadProducts() }
        }
    }

    private func loadProducts() async {
        do { products = try await StoreMeshAPI().products(token: token) }
        catch { error = "Unable to load products. Check the BFF connection." }
    }
}

private struct OrdersView: View {
    let token: String
    @State private var orders: [StoreOrder] = []
    @State private var error = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My orders").font(.largeTitle.bold())
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            else if orders.isEmpty { ContentUnavailableView("No orders yet", systemImage: "shippingbox") }
            else { ForEach(orders) { order in VStack(alignment: .leading, spacing: 5) { Text(order.orderId).font(.headline); Text(order.status.replacingOccurrences(of: "ORDER_STATUS_", with: "").capitalized).foregroundStyle(.secondary); Text(order.totalText).font(.subheadline.weight(.semibold)) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14)) } }
        }.task { do { orders = try await StoreMeshAPI().orders(token: token) } catch { error = "Unable to load your orders." } }
    }
}

private struct ProductCard: View {
    let product: StoreProduct
    var onTap: () -> Void
    var body: some View { VStack(alignment: .leading, spacing: 8) { RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.12)).frame(height: 105).overlay(Text(product.name.prefix(1)).font(.largeTitle.bold()).foregroundStyle(.blue)); Text(product.name).font(.headline).lineLimit(1); Text(product.description).font(.caption).foregroundStyle(.secondary).lineLimit(2); Text(product.priceText).font(.headline).foregroundStyle(.green) }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle()).onTapGesture(perform: onTap) }
}

private struct ProductDetailView: View {
    let product: StoreProduct
    @Environment(\.dismiss) private var dismiss
    @State private var addedToCart = false
    var body: some View { NavigationStack { VStack(alignment: .leading, spacing: 18) { RoundedRectangle(cornerRadius: 20).fill(Color.blue.opacity(0.12)).frame(height: 220).overlay(Text(product.name.prefix(1)).font(.system(size: 80, weight: .bold)).foregroundStyle(.blue)); Text(product.name).font(.largeTitle.bold()); Text(product.priceText).font(.title3.weight(.semibold)).foregroundStyle(.green); Text(product.description).foregroundStyle(.secondary); Button(addedToCart ? "Added to cart" : "Add to cart") { addedToCart = true }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity); Spacer() }.padding().navigationTitle("Product").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } } } }
}

private struct MenuView: View {
    var onOrders: () -> Void
    var onShop: () -> Void
    var onLogout: () -> Void
    var body: some View { NavigationStack { List { Button(action: onShop) { Label("Shop", systemImage: "bag") }; Button(action: onOrders) { Label("My orders", systemImage: "shippingbox") }; Label("Saved items", systemImage: "heart"); Button("Sign out", role: .destructive, action: onLogout) }.navigationTitle("StoreMesh") } }
}
