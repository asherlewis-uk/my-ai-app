import SwiftUI

struct AppRootView: View {
  @Environment(AppModel.self) private var appModel

  var body: some View {
    @Bindable var appModel = appModel

    ZStack(alignment: .top) {
      LinearGradient(
        colors: [
          Color(red: 0.97, green: 0.95, blue: 0.90),
          Color(red: 0.86, green: 0.90, blue: 0.83),
          Color(red: 0.74, green: 0.82, blue: 0.79)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      switch appModel.launchState {
      case .launching, .loadingProfile:
        LaunchingView()
      case .signedOut:
        AuthenticationView(
          sessionStore: appModel.sessionStore
        )
      case .needsOnboarding:
        OnboardingFlowView(profileStore: appModel.profileStore) {
          appModel.launchState = .ready
        }
      case .ready:
        TabView(selection: $appModel.selectedTab) {
          NavigationStack {
            ChatView(conversationStore: appModel.conversationStore)
          }
          .tabItem { Label(AppTab.companion.title, systemImage: AppTab.companion.systemImage) }
          .tag(AppTab.companion)

          NavigationStack {
            MemoryListView(memoryStore: appModel.memoryStore)
          }
          .tabItem { Label(AppTab.memory.title, systemImage: AppTab.memory.systemImage) }
          .tag(AppTab.memory)

          NavigationStack {
            SettingsView(
              profileStore: appModel.profileStore,
              sessionStore: appModel.sessionStore
            )
          }
          .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage) }
          .tag(AppTab.settings)
        }
        .tint(Color(red: 0.12, green: 0.27, blue: 0.24))
      }

      if let bannerMessage = appModel.bannerMessage, !bannerMessage.isEmpty {
        Text(bannerMessage)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial, in: Capsule())
          .padding(.top, 16)
      }
    }
  }
}

private struct LaunchingView: View {
  var body: some View {
    VStack(spacing: 18) {
      Spacer()
      Image(systemName: "brain.head.profile")
        .font(.system(size: 48, weight: .bold))
        .foregroundStyle(Color(red: 0.12, green: 0.27, blue: 0.24))
      Text("NestMind")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
      Text("Personal context, private by default, and ready when your session is.")
        .multilineTextAlignment(.center)
        .font(.body)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 32)
      ProgressView()
        .padding(.top, 10)
      Spacer()
    }
  }
}

