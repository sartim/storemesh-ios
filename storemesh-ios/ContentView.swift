import SwiftUI

struct ContentView: View {
    @AppStorage("storemesh.accessToken") private var accessToken = ""
    @State private var phase: AppPhase = .splash

    var body: some View {
        Group {
            switch phase {
            case .splash: SplashView()
            case .login: LoginView { token in accessToken = token; phase = .shop }
            case .shop: ShopView(token: accessToken) { accessToken = ""; phase = .login }
            }
        }.task {
            try? await Task.sleep(for: .milliseconds(800))
            phase = accessToken.isEmpty ? .login : .shop
        }
    }
}

private enum AppPhase { case splash, login, shop }

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.16, blue: 0.27).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "bag.fill").font(.system(size: 64)).foregroundStyle(.yellow)
                Text("StoreMesh").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Everything you need, together.").foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

private struct LoginView: View {
    var onLogin: (String) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section { Text("Welcome back").font(.largeTitle.bold()); Text("Sign in to discover products and manage your orders.").foregroundStyle(.secondary) }
                Section("Account") {
                    TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
                Button(isLoading ? "Signing in…" : "Sign in") {
                    isLoading = true
                    Task {
                        do { onLogin(try await StoreMeshAPI().login(email: email, password: password).accessToken) }
                        catch let requestError { error = requestError.localizedDescription; isLoading = false }
                    }
                }.disabled(isLoading || email.isEmpty || password.isEmpty)
            }.navigationTitle("StoreMesh")
        }
    }
}

private struct ShopView: View {
    let token: String
    var onLogout: () -> Void
    @State private var products: [StoreProduct] = []
    @State private var search = ""
    @State private var showMenu = false
    @State private var error = ""
    private var filtered: [StoreProduct] { products.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.description.localizedCaseInsensitiveContains(search) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Find your next favourite").font(.largeTitle.bold())
                    Text("Curated picks, everyday deals.").foregroundStyle(.secondary)
                    TextField("Search products", text: $search).textFieldStyle(.roundedBorder)
                    if !error.isEmpty { Text(error).foregroundStyle(.red) }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) { ForEach(filtered) { ProductCard(product: $0) } }
                }.padding()
            }.navigationTitle("Shop")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { showMenu = true } label: { Label("Menu", systemImage: "line.3.horizontal") } }
                ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bag") }
            }.sheet(isPresented: $showMenu) { MenuView(onLogout: onLogout) }
            .task { await loadProducts() }
        }
    }

    private func loadProducts() async {
        do { products = try await StoreMeshAPI().products(token: token) }
        catch let requestError { error = requestError.localizedDescription }
    }
}

private struct ProductCard: View {
    let product: StoreProduct
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.12)).frame(height: 105).overlay(Text(product.name.prefix(1)).font(.largeTitle.bold()).foregroundStyle(.blue))
            Text(product.name).font(.headline).lineLimit(1)
            Text(product.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            Text(product.priceText).font(.headline).foregroundStyle(.green)
        }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct MenuView: View {
    var onLogout: () -> Void
    var body: some View {
        NavigationStack { List { Label("Shop", systemImage: "bag"); Label("My orders", systemImage: "shippingbox"); Label("Saved items", systemImage: "heart"); Button("Sign out", role: .destructive, action: onLogout) }.navigationTitle("StoreMesh") }
    }
}
