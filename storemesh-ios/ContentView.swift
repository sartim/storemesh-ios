import SwiftUI

struct ContentView: View {
    @AppStorage("storemesh.accessToken") private var accessToken = ""
    @AppStorage("storemesh.refreshToken") private var refreshToken = ""
    @State private var phase: AppPhase = .splash

    var body: some View {
        Group {
            switch phase {
            case .splash: SplashView()
            case .login: LoginView { session in
                accessToken = session.accessToken
                refreshToken = session.refreshToken
                phase = .shop
            }
            case .shop: ShopView(token: accessToken) { accessToken = ""; refreshToken = ""; phase = .login }
            }
        }.task {
            try? await Task.sleep(for: .milliseconds(800))
            if accessToken.isEmpty, !refreshToken.isEmpty,
               let session = try? await StoreMeshAPI().refresh(refreshToken: refreshToken) {
                accessToken = session.accessToken
                refreshToken = session.refreshToken
            }
            phase = accessToken.isEmpty ? .login : .shop
        }
    }
}

private enum AppPhase { case splash, login, shop }

private struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.16, blue: 0.27).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                    .scaleEffect(isAnimating ? 1 : 0.78)
                    .opacity(isAnimating ? 1 : 0.3)
                Text("StoreMesh").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Everything you need, together.").foregroundStyle(.white.opacity(0.8))
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.65)) { isAnimating = true }
        }
    }
}

private struct LoginView: View {
    var onLogin: (StoreLogin) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Welcome back", systemImage: "bag.fill")
                        .font(.largeTitle.bold())
                    Text("Sign in to discover products and manage your orders.")
                        .foregroundStyle(.secondary)
                }
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .accessibilityLabel("Password")
                }
                if !error.isEmpty {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .accessibilityLiveRegion(.assertive)
                }
                Section {
                    Button {
                        signIn()
                    } label: {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "Signing in…" : "Sign in")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    .accessibilityHint("Signs in through the StoreMesh BFF")
                }
            }.navigationTitle("StoreMesh")
        }
    }

    private func signIn() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.contains("@") else {
            error = "Enter a valid email address."
            return
        }
        error = ""
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let session = try await StoreMeshAPI().login(email: normalizedEmail, password: password)
                onLogin(session)
            } catch {
                self.error = "Sign in failed. Check your credentials and try again."
            }
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
