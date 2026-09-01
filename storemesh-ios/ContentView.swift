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
            case .shop: ShopView(token: accessToken) {
                accessToken = ""
                refreshToken = ""
                phase = .login
            }
            }
        }
        .task {
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
