import SwiftUI

struct ProfileEditorView: View {
  let profileStore: ProfileStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    @Bindable var profileStore = profileStore

    Form {
      ProfileFormSections(profileStore: profileStore)
    }
    .navigationTitle("Profile")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") {
          Task {
            do {
              try await profileStore.saveDraft(markOnboardingComplete: profileStore.draft.isOnboardingComplete)
              dismiss()
            } catch {
              profileStore.errorMessage = error.localizedDescription
            }
          }
        }
        .disabled(profileStore.isSaving)
      }
    }
  }
}

struct ProfileFormSections: View {
  let profileStore: ProfileStore

  var body: some View {
    @Bindable var profileStore = profileStore

    Section("Identity") {
      TextField("Display name", text: $profileStore.draft.displayName)
      TextField("Preferred name", text: $profileStore.draft.preferredName)
      TextField("Assistant tone", text: $profileStore.draft.assistantTone, axis: .vertical)
      TextField("Support style", text: $profileStore.draft.supportStyle, axis: .vertical)
    }

    Section("Personal context") {
      TextField("Life focuses", text: $profileStore.draft.lifeFocusesText, axis: .vertical)
      TextField("Things you like", text: $profileStore.draft.likesText, axis: .vertical)
      TextField("Things you dislike", text: $profileStore.draft.dislikesText, axis: .vertical)
      TextField("Boundaries", text: $profileStore.draft.boundariesText, axis: .vertical)
    }

    Section("Onboarding answers") {
      ForEach(OnboardingPrompt.allCases) { prompt in
        TextField(prompt.rawValue, text: binding(for: prompt, store: profileStore), axis: .vertical)
          .lineLimit(3...6)
      }
    }

    Section("Summary") {
      TextEditor(text: $profileStore.draft.summary)
        .frame(minHeight: 110)
    }

    if let errorMessage = profileStore.errorMessage {
      Section {
        Text(errorMessage)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.red)
      }
    }
  }

  private func binding(for prompt: OnboardingPrompt, store: ProfileStore) -> Binding<String> {
    Binding(
      get: { store.draft.onboardingAnswers[prompt.rawValue, default: ""] },
      set: { store.draft.onboardingAnswers[prompt.rawValue] = $0 }
    )
  }
}
