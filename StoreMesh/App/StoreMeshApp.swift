import SwiftUI

@main
struct StoreMeshApp: App {
    @State private var tokens: OIDCTokens?
    @State private var phase: AppPhase = .splash
    private let tokenStore = KeychainTokenStore()

    var body: some Scene {
        WindowGroup {
            Group {
                switch phase {
                case .splash: SplashView()
                case .login: LoginView { newTokens in try? tokenStore.save(newTokens); tokens = newTokens; phase = .shop }
                case .shop: CatalogView(accessToken: tokens?.accessToken ?? "")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sign out") { tokenStore.clear(); tokens = nil; phase = .login } } }
                }
            }.task {
                try? await Task.sleep(for: .milliseconds(800))
                tokens = tokenStore.load()
                phase = tokens == nil ? .login : .shop
            }
        }
    }
}

private enum AppPhase { case splash, login, shop }

private struct SplashView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag.fill").font(.system(size: 58)).foregroundStyle(.white).frame(width: 104, height: 104).background(Color.storeMeshBlue, in: RoundedRectangle(cornerRadius: 28))
            Text("StoreMesh").font(.largeTitle.bold())
            Text("Everything you need, delivered to you.").foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.storeMeshBackground)
    }
}
