import SwiftUI

struct LoginView: View {
    let onLogin: (OIDCTokens) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let auth = OIDCAuth()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("StoreMesh").font(.title2.bold()).foregroundStyle(Color.storeMeshBlue)
            Text("Welcome back").font(.largeTitle.bold())
            Text("Sign in to continue shopping").foregroundStyle(.secondary)
            if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center) }
            TextField("Email or phone number", text: .constant("")).textFieldStyle(.roundedBorder).textContentType(.username)
            SecureField("Password", text: .constant("")).textFieldStyle(.roundedBorder).textContentType(.password)
            HStack { Spacer(); Button("Forgot password?") {}.font(.caption).foregroundStyle(Color.storeMeshBlue) }
            Button { signIn() } label: {
                Text(isLoading ? "Signing in…" : "Log in").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).disabled(isLoading)
            HStack { Rectangle().frame(height: 1).foregroundStyle(.quaternary); Text("or").foregroundStyle(.secondary); Rectangle().frame(height: 1).foregroundStyle(.quaternary) }
            Button { signIn() } label: {
                Label("Continue securely with StoreMesh", systemImage: "lock.shield")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
            .disabled(isLoading)
            Text("Your data is protected with secure sign-in using OIDC and PKCE.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).multilineTextAlignment(.center)
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
