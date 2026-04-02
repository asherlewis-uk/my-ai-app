import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class AppModel {
  enum LaunchState {
    case launching
    case signedOut
    case loadingProfile
    case needsOnboarding
    case ready
  }

  let config: AppConfig
  let supabase: SupabaseService
  let sessionStore: SessionStore
  let profileStore: ProfileStore
  let conversationStore: ConversationStore
  let memoryStore: MemoryStore

  var launchState: LaunchState = .launching
  var selectedTab: AppTab = .companion
  var bannerMessage: String?

  private var hasStarted = false

  init() {
    do {
      let config = try AppConfig.load()
      self.config = config
      let supabase = SupabaseService(config: config)
      self.supabase = supabase
      let sessionStore = SessionStore(supabase: supabase)
      self.sessionStore = sessionStore
      let apiClient = APIClient(
        config: config,
        accessTokenProvider: { @MainActor in
          sessionStore.accessToken
        }
      )
      self.profileStore = ProfileStore(apiClient: apiClient)
      self.conversationStore = ConversationStore(apiClient: apiClient)
      self.memoryStore = MemoryStore(apiClient: apiClient)

      sessionStore.onSessionChange = { [weak self] session in
        await self?.handleSessionChange(session)
      }
    } catch {
      fatalError("App configuration failed: \(error.localizedDescription)")
    }
  }

  func start() {
    guard !hasStarted else { return }
    hasStarted = true
    Task {
      await sessionStore.start()
    }
  }

  private func handleSessionChange(_ session: Session?) async {
    guard session != nil else {
      profileStore.reset()
      conversationStore.reset()
      memoryStore.reset()
      launchState = .signedOut
      return
    }

    launchState = .loadingProfile

    do {
      let profile = try await profileStore.loadProfile(seedDisplayName: sessionStore.pendingDisplayName)
      async let memoryTask = memoryStore.refresh()
      async let conversationTask = conversationStore.loadLatestConversation()
      _ = await (try? memoryTask, try? conversationTask)
      launchState = profile.isOnboardingComplete ? .ready : .needsOnboarding
      sessionStore.pendingDisplayName = nil
    } catch {
      bannerMessage = error.localizedDescription
      launchState = .needsOnboarding
    }
  }
}

