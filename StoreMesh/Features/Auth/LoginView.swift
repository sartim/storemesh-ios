import SwiftUI

struct LoginView: View {
    let onLogin: (OIDCTokens) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let auth = OIDCAuth()

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "bag.fill").font(.system(size: 54)).foregroundStyle(.tint)
            Text("Welcome to StoreMesh").font(.largeTitle.bold())
            Text("Sign in to browse products and manage your orders.").multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center) }
            Button { signIn() } label: {
                Label(isLoading ? "Signing in…" : "Continue with StoreMesh", systemImage: "person.crop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding(28)
    }

    private func signIn() {
        isLoading = true
        Task {
            do { onLogin(try await auth.signIn()) }
            catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}
