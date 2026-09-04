import AuthenticationServices
import CryptoKit
import Foundation

struct OIDCTokens: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

enum OIDCAuthError: LocalizedError {
    case unavailable
    case cancelled
    case invalidCallback
    case tokenExchangeFailed

    var errorDescription: String? {
        switch self {
        case .unavailable: "OIDC sign-in is unavailable."
        case .cancelled: "OIDC sign-in was cancelled."
        case .invalidCallback: "Keycloak returned an invalid callback."
        case .tokenExchangeFailed: "Unable to exchange the authorization code."
        }
    }
}

/// Native iOS Authorization Code + PKCE flow for the public StoreMesh client.
@MainActor
final class OIDCAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let issuer = URL(string: "http://localhost:8081/realms/storemesh")!
    private let clientID = "storemesh-ios"
    private let callbackScheme = "storemesh-ios"
    private var session: ASWebAuthenticationSession?

    func signIn() async throws -> OIDCTokens {
        let verifier = Self.randomString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        var components = URLComponents(url: issuer.appending(path: "protocol/openid-connect/auth"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: "\(callbackScheme)://oauth/callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid profile email"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let authorizationURL = components.url else { throw OIDCAuthError.unavailable }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(url: authorizationURL, callbackURLScheme: callbackScheme) { [weak self] url, error in
                self?.session = nil
                if let url { continuation.resume(returning: url) }
                else if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                    continuation.resume(throwing: OIDCAuthError.cancelled)
                } else { continuation.resume(throwing: error ?? OIDCAuthError.invalidCallback) }
            }
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
            self.session = authSession
            guard authSession.start() else {
                continuation.resume(throwing: OIDCAuthError.unavailable)
                return
            }
        }
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw OIDCAuthError.invalidCallback
        }
        return try await exchange(code: code, verifier: verifier)
    }

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func exchange(code: String, verifier: String) async throws -> OIDCTokens {
        let endpoint = issuer.appending(path: "protocol/openid-connect/token")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = [
            "grant_type=authorization_code", "client_id=\(clientID)",
            "code=\(code.urlEncoded)", "redirect_uri=\(callbackScheme)%3A%2F%2Foauth%2Fcallback",
            "code_verifier=\(verifier.urlEncoded)"
        ].joined(separator: "&").data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw OIDCAuthError.tokenExchangeFailed }
        return try JSONDecoder().decode(OIDCTokens.self, from: data)
    }

    private static func randomString(length: Int) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    private static func codeChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
    }
}

private extension Data {
    var base64URLEncoded: String { base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "") }
}

private extension String {
    var urlEncoded: String { addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self }
}
