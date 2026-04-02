import AuthenticationServices
import CryptoKit
import Foundation

enum AppleSignInSupport {
  static func randomNonce(length: Int = 32) -> String {
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      var randoms = [UInt8](repeating: 0, count: 16)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
      if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce.")
      }

      randoms.forEach { random in
        if remainingLength == 0 {
          return
        }

        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }

  static func sha256(_ input: String) -> String {
    SHA256.hash(data: Data(input.utf8))
      .compactMap { String(format: "%02x", $0) }
      .joined()
  }

  static func idToken(from authorization: ASAuthorization) throws -> String {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      throw AppleSignInError.invalidCredential
    }

    guard let tokenData = credential.identityToken else {
      throw AppleSignInError.missingIdentityToken
    }

    guard let token = String(data: tokenData, encoding: .utf8) else {
      throw AppleSignInError.invalidIdentityToken
    }

    return token
  }

  static func displayName(from authorization: ASAuthorization) -> String? {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      return nil
    }

    let formatter = PersonNameComponentsFormatter()
    let value = formatter.string(from: credential.fullName ?? PersonNameComponents())
    return value.trimmedOrNil
  }
}

enum AppleSignInError: LocalizedError {
  case invalidCredential
  case missingIdentityToken
  case invalidIdentityToken

  var errorDescription: String? {
    switch self {
    case .invalidCredential:
      return "Apple did not return a valid credential."
    case .missingIdentityToken:
      return "Apple did not provide an identity token."
    case .invalidIdentityToken:
      return "Apple returned an unreadable identity token."
    }
  }
}

