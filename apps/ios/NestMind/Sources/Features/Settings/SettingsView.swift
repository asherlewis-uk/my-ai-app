import SwiftUI

struct SettingsView: View {
  let profileStore: ProfileStore
  let sessionStore: SessionStore

  var body: some View {
    List {
      Section("Identity") {
        if let profile = profileStore.profile {
          VStack(alignment: .leading, spacing: 6) {
            Text(profile.preferredName.isEmpty ? profile.displayName : profile.preferredName)
              .font(.headline)
            Text(profile.householdName ?? "Private household")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        NavigationLink("Edit profile") {
          ProfileEditorView(profileStore: profileStore)
        }
      }

      Section("Security") {
        Text("All model traffic routes through the Supabase Edge Function layer. The app never stores your Ollama API key.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Section {
        Button("Sign out", role: .destructive) {
          Task {
            await sessionStore.signOut()
          }
        }
      }
    }
    .navigationTitle("Settings")
  }
}
