import SwiftUI

struct ContentView: View {
    private let session = SessionStore()
    @State private var phase: AppPhase = .splash

    var body: some View {
        Group {
            switch phase {
            case .splash: SplashView()
            case .login: LoginView { authenticatedSession in
                session.save(authenticatedSession)
                phase = .shop
            }
            case .shop: ShopView(token: session.accessToken) {
                session.clear()
                phase = .login
            }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(800))
            if session.accessToken.isEmpty, !session.refreshToken.isEmpty,
               let refreshed = try? await StoreMeshAPI().refresh(refreshToken: session.refreshToken) {
                session.save(refreshed)
            }
            phase = session.accessToken.isEmpty ? .login : .shop
        }
    }
}

private enum AppPhase { case splash, login, shop }
