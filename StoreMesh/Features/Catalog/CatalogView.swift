import SwiftUI

struct CatalogView: View {
    let accessToken: String
    @State private var products: [Product] = []
    @State private var cart = Cart(lines: [])
    @State private var orders: [Order] = []
    @State private var query = ""
    @State private var selectedProduct: Product?
    @State private var showingCheckout = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    private let api = APIClient()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { homeView }.tabItem { Label("Shop", systemImage: "house.fill") }.tag(0)
            NavigationStack { ordersView }.tabItem { Label("Orders", systemImage: "shippingbox") }.tag(1)
            NavigationStack { CartView(products: products, cart: $cart, onChange: saveCart, onClear: clearCart, onCheckout: { showingCheckout = true }) }.tabItem { Label("Cart", systemImage: "cart.fill") }.tag(2)
            NavigationStack { profileView }.tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(3)
        }
        .tint(.storeMeshBlue)
        .task { await load() }
        .alert("StoreMesh", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK") {} } message: { Text(errorMessage ?? "") }
        .sheet(item: $selectedProduct) { product in ProductDetailView(product: product) { addToCart(product); selectedProduct = nil } }
        .sheet(isPresented: $showingCheckout) { CheckoutView(cart: cart, products: products) { await checkout(); showingCheckout = false } }
    }

    private var homeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack { VStack(alignment: .leading, spacing: 3) { Text("STOREMESH").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary); Text("Objects for living well").font(.title2.bold()) }; Spacer(); Button { selectedTab = 2 } label: { CartBadge(count: cart.lines.reduce(0) { $0 + $1.quantity }) } }
                TextField("Search the collection", text: $query).textFieldStyle(.plain).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08)))
                DealBanner { withAnimation { query = "" } }
                sectionHeader("Featured now", detail: "\(min(filteredProducts.count, 4)) pieces")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) { ForEach(Array(filteredProducts.prefix(4))) { product in ProductCard(product: product) { selectedProduct = product } } }
                sectionHeader("All products", detail: "\(filteredProducts.count) pieces")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) { ForEach(filteredProducts) { product in ProductCard(product: product) { selectedProduct = product } } }
            }.padding()
        }.background(Color.storeMeshBackground).navigationBarHidden(true)
    }

    private func sectionHeader(_ title: String, detail: String) -> some View { HStack { Text(title).font(.title3.bold()); Spacer(); Text(detail).font(.subheadline).foregroundStyle(.secondary) } }
    private var ordersView: some View { Group { if orders.isEmpty { ContentUnavailableView("No orders yet", systemImage: "shippingbox", description: Text("Your placed orders will appear here.")) } else { List(orders) { OrderRow(order: $0) } } }.navigationTitle("Orders") }
    private var profileView: some View { List { Section { Label("Customer account", systemImage: "person.crop.circle.fill").font(.headline); Text("Manage your account, addresses, and payment methods").foregroundStyle(.secondary) }; Section { ForEach(["My details", "Addresses", "Payment methods", "Notifications", "Help & support", "Settings"], id: \.self) { Label($0, systemImage: "chevron.right").labelStyle(.titleAndIcon) } } }.navigationTitle("Profile") }
    private var filteredProducts: [Product] { products.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.description.localizedCaseInsensitiveContains(query) } }
    private func load() async { do { products = try await api.graphQLProducts(accessToken: accessToken); cart = (try? await api.graphQLCart(accessToken: accessToken)) ?? Cart(lines: []); orders = (try? await api.orders(accessToken: accessToken)) ?? [] } catch { errorMessage = "Start the local BFF and try again." } }
    private func addToCart(_ product: Product) { var next = cart; if let index = next.lines.firstIndex(where: { $0.productId == product.id }) { next.lines[index].quantity += 1 } else { next.lines.append(CartLine(productId: product.id, quantity: 1)) }; Task { await saveCart(next) } }
    private func saveCart(_ next: Cart) async { do { cart = try await api.graphQLSaveCart(next, accessToken: accessToken) } catch { errorMessage = "Unable to save your cart." } }
    private func clearCart() async { try? await api.graphQLClearCart(accessToken: accessToken); cart = Cart(lines: []) }
    private func checkout() async { do { let order = try await api.graphQLCreateOrder(cart, accessToken: accessToken); try await api.graphQLClearCart(accessToken: accessToken); cart = Cart(lines: []); orders.insert(order, at: 0); selectedTab = 1 } catch { errorMessage = "Checkout failed. Please try again." } }
}

private struct CartBadge: View { let count: Int; var body: some View { Image(systemName: "cart").font(.title3).overlay(alignment: .topTrailing) { if count > 0 { Text("\(count)").font(.caption2.bold()).foregroundStyle(.white).padding(4).background(.red, in: Circle()).offset(x: 8, y: -8) } } } }
private struct DealBanner: View { let onShop: () -> Void; var body: some View { HStack { VStack(alignment: .leading, spacing: 8) { Text("WEEKEND EDIT").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.secondary); Text("Good design,\nbetter prices.").font(.title2.bold()); Button("Shop the collection", action: onShop).buttonStyle(.borderedProminent) }; Spacer(); Image(systemName: "sparkles").font(.system(size: 42)).foregroundStyle(.orange) }.padding(20).background(Color.storeMeshMint, in: RoundedRectangle(cornerRadius: 22)) } }
private struct ProductCard: View { let product: Product; let onTap: () -> Void; var body: some View { Button(action: onTap) { VStack(alignment: .leading, spacing: 9) { ProductArtwork(product: product, height: 130); Text(product.name).font(.headline).lineLimit(2); Text(product.description).font(.caption).foregroundStyle(.secondary).lineLimit(2); Text("\(product.currency) \(Double(product.priceMinor) / 100, specifier: "%.2f")").font(.subheadline.bold()).foregroundStyle(.green) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.white, in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain) } }
private struct ProductDetailView: View { let product: Product; let onAdd: () -> Void; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { ProductArtwork(product: product, height: 280); Text(product.name).font(.largeTitle.bold()); Text("\(product.currency) \(Double(product.priceMinor) / 100, specifier: "%.2f")").font(.title3.bold()).foregroundStyle(.green); Text(product.description).foregroundStyle(.secondary); Button("Add to cart", action: onAdd).buttonStyle(.borderedProminent).frame(maxWidth: .infinity) }.padding() } } }
private struct ProductArtwork: View { let product: Product; let height: CGFloat; private var imageURL: URL? { URL(string: "https://picsum.photos/seed/storemesh-\(product.sku ?? product.id)/800/800") }; var body: some View { AsyncImage(url: imageURL) { phase in if let image = phase.image { image.resizable().scaledToFill() } else { ZStack { RoundedRectangle(cornerRadius: 16).fill(Color.storeMeshBlue.opacity(0.1)); Image(systemName: "shippingbox.fill").font(.system(size: 40)).foregroundStyle(Color.storeMeshBlue) } } }.frame(maxWidth: .infinity).frame(height: height).clipShape(RoundedRectangle(cornerRadius: 16)) } }
private struct OrderRow: View { let order: Order; var body: some View { VStack(alignment: .leading, spacing: 8) { HStack { Text(order.id).font(.headline); Spacer(); Text(order.status.replacingOccurrences(of: "ORDER_STATUS_", with: "").capitalized).font(.caption.bold()).padding(6).background(Color.storeMeshMint, in: Capsule()) }; Text("\(order.currency) \(Double(order.totalMinor) / 100, specifier: "%.2f")").font(.subheadline.bold()); Label("Order placed", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }.padding(.vertical, 6) } }
private struct CheckoutView: View { let cart: Cart; let products: [Product]; let onPlaceOrder: () async -> Void; @State private var loading = false; var total: Int { cart.lines.reduce(0) { sum, line in sum + (products.first(where: { $0.id == line.productId })?.priceMinor ?? 0) * line.quantity } }; var body: some View { VStack(alignment: .leading, spacing: 18) { Text("Checkout").font(.largeTitle.bold()); Text("Delivery address").font(.headline); Text("Nairobi, Kenya\nStandard delivery · 2–3 business days").padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14)); HStack { Text("Total").font(.headline); Spacer(); Text("USD \(Double(total) / 100, specifier: "%.2f")").font(.headline).foregroundStyle(.green) }; Button { loading = true; Task { await onPlaceOrder(); loading = false } } label: { Text(loading ? "Placing order…" : "Place order").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).disabled(loading || cart.lines.isEmpty); Spacer() }.padding().presentationDetents([.medium]) } }

extension Color { static let storeMeshBlue = Color(red: 0.08, green: 0.37, blue: 0.93); static let storeMeshMint = Color(red: 0.86, green: 0.97, blue: 0.91); static let storeMeshBackground = Color(red: 0.98, green: 0.98, blue: 0.97) }
