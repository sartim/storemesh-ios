import SwiftUI

@main
struct StoreMeshApp: App {
    @State private var tokens: OIDCTokens?
    private let tokenStore = KeychainTokenStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let tokens { CatalogView(accessToken: tokens.accessToken).toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sign out") { tokenStore.clear(); self.tokens = nil } } } }
                else { LoginView { tokens in try? tokenStore.save(tokens); self.tokens = tokens } }
            }
            .task { if tokens == nil { tokens = tokenStore.load() } }
        }
    }
}
