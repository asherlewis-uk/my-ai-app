import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class SessionStore {
  private let supabase: SupabaseService
  private var authTask: Task<Void, Never>?

  var session: Session?
  var accessToken: String?
  var isBusy = false
  var errorMessage: String?
  var pendingDisplayName: String?

  var onSessionChange: (@MainActor (Session?) async -> Void)?

  init(supabase: SupabaseService) {
    self.supabase = supabase
  }

  func start() async {
    guard authTask == nil else { return }
    await supabase.client.auth.startAutoRefresh()

    do {
      let currentSession = try await supabase.client.auth.session
      apply(session: currentSession)
      if let onSessionChange {
        await onSessionChange(currentSession)
      }
    } catch {
      apply(session: nil)
      if let onSessionChange {
        await onSessionChange(nil)
      }
    }

    authTask = Task {
      for await (_, session) in await supabase.client.auth.authStateChanges {
        await MainActor.run {
          self.apply(session: session)
        }

        if let onSessionChange {
          await onSessionChange(session)
        }
      }
    }
  }

  func signInWithApple(idToken: String, nonce: String, displayName: String?) async throws {
    isBusy = true
    defer { isBusy = false }

    let session = try await supabase.client.auth.signInWithIdToken(
      credentials: OpenIDConnectCredentials(
        provider: .apple,
        idToken: idToken,
        nonce: nonce
      )
    )

    pendingDisplayName = displayName
    apply(session: session)
    if let onSessionChange {
      await onSessionChange(session)
    }
  }

  func signOut() async {
    isBusy = true
    defer { isBusy = false }

    do {
      try await supabase.client.auth.signOut()
      pendingDisplayName = nil
      apply(session: nil)
      if let onSessionChange {
        await onSessionChange(nil)
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func apply(session: Session?) {
    self.session = session
    accessToken = session?.accessToken
  }
}
