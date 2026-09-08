import SwiftUI

struct LoginView: View {
    let onLogin: (OIDCTokens) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let api = APIClient()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("StoreMesh").font(.title2.bold()).foregroundStyle(Color.storeMeshBlue)
            Text("Welcome back").font(.largeTitle.bold())
            Text("Sign in to continue shopping").foregroundStyle(.secondary)
            if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center) }
            TextField("Email or phone number", text: $email).textFieldStyle(.roundedBorder).textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder).textContentType(.password)
            HStack { Spacer(); Button("Forgot password?") {}.font(.caption).foregroundStyle(Color.storeMeshBlue) }
            Button { signInWithBFF() } label: {
                Text(isLoading ? "Signing in…" : "Log in").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).disabled(isLoading)
            Text("Local development signs in through the StoreMesh BFF. OIDC and PKCE are enabled when a Keycloak environment is configured.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).multilineTextAlignment(.center)
        }
        .padding(28)
    }

    private func signInWithBFF() {
        isLoading = true
        Task {
            do {
                let response = try await api.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
                onLogin(OIDCTokens(accessToken: response.accessToken, refreshToken: response.refreshToken, expiresIn: nil))
            } catch { errorMessage = "Unable to sign in. Check the BFF and your credentials." }
            isLoading = false
        }
    }
}
