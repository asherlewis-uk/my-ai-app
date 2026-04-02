import AuthenticationServices
import SwiftUI

struct AuthenticationView: View {
  let sessionStore: SessionStore
  @State private var nonce = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Spacer()

      VStack(alignment: .leading, spacing: 14) {
        Text("Your private AI, tuned to each person.")
          .font(.system(size: 38, weight: .bold, design: .serif))
          .foregroundStyle(Color(red: 0.11, green: 0.19, blue: 0.16))

        Text("NestMind keeps household accounts separate, learns from profile and conversation context, and sends every model call through your secure backend instead of the app itself.")
          .font(.title3)
          .foregroundStyle(Color.black.opacity(0.72))
      }

      VStack(alignment: .leading, spacing: 12) {
        AuthFeatureRow(title: "Separate memory per person", subtitle: "No shared household memory in v1.")
        AuthFeatureRow(title: "Photo-aware conversations", subtitle: "Attach images and let the backend decide when vision context matters.")
        AuthFeatureRow(title: "Server-side Ollama access", subtitle: "Your Ollama API key stays off-device.")
      }

      if let errorMessage = sessionStore.errorMessage {
        Text(errorMessage)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.red)
      }

      SignInWithAppleButton(.continue) { request in
        nonce = AppleSignInSupport.randomNonce()
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInSupport.sha256(nonce)
      } onCompletion: { result in
        Task {
          do {
            let authorization = try result.get()
            let idToken = try AppleSignInSupport.idToken(from: authorization)
            let displayName = AppleSignInSupport.displayName(from: authorization)
            try await sessionStore.signInWithApple(idToken: idToken, nonce: nonce, displayName: displayName)
          } catch {
            sessionStore.errorMessage = error.localizedDescription
          }
        }
      }
      .signInWithAppleButtonStyle(.black)
      .frame(height: 54)
      .disabled(sessionStore.isBusy)

      Spacer()
    }
    .padding(24)
  }
}

private struct AuthFeatureRow: View {
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Circle()
        .fill(Color(red: 0.19, green: 0.38, blue: 0.34))
        .frame(width: 8, height: 8)
        .padding(.top, 8)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

