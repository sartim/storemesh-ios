import SwiftUI

struct SplashView: View {
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
        .task { withAnimation(.easeOut(duration: 0.65)) { isAnimating = true } }
    }
}

struct LoginView: View {
    var onLogin: (StoreLogin) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Welcome back", systemImage: "bag.fill").font(.largeTitle.bold())
                    Text("Sign in to discover products and manage your orders.").foregroundStyle(.secondary)
                }
                Section("Account") {
                    TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress).textContentType(.username).autocorrectionDisabled()
                    SecureField("Password", text: $password).textContentType(.password)
                }
                if !error.isEmpty { Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                Section {
                    Button(action: signIn) {
                        HStack { if isLoading { ProgressView().tint(.white) }; Text(isLoading ? "Signing in…" : "Sign in") }
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                }
            }.navigationTitle("StoreMesh")
        }
    }

    private func signIn() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.contains("@") else { error = "Enter a valid email address."; return }
        error = ""; isLoading = true
        Task {
            defer { isLoading = false }
            do { onLogin(try await StoreMeshAPI().login(email: normalizedEmail, password: password)) }
            catch { self.error = "Sign in failed. Check your credentials and try again." }
        }
    }
}
