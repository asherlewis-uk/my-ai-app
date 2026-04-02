import SwiftUI

struct OnboardingFlowView: View {
  let profileStore: ProfileStore
  let onCompleted: () -> Void

  var body: some View {
    @Bindable var profileStore = profileStore

    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            Text("Teach NestMind how to help.")
              .font(.system(size: 34, weight: .bold, design: .serif))
              .padding(.top, 12)

            Text("Start with stable facts, preferences, and the support style you want. The assistant will combine this with curated memory summaries instead of blindly replaying every transcript.")
              .font(.body)
              .foregroundStyle(.secondary)

            profileCard

            Form {
              ProfileFormSections(profileStore: profileStore)
            }
            .frame(minHeight: 900)
            .scrollDisabled(true)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
          }
          .padding(20)
        }

        Button {
          Task {
            do {
              try await profileStore.saveDraft(markOnboardingComplete: true)
              onCompleted()
            } catch {
              profileStore.errorMessage = error.localizedDescription
            }
          }
        } label: {
          HStack {
            Text(profileStore.isSaving ? "Saving..." : "Finish onboarding")
            Image(systemName: "arrow.up.right.circle.fill")
          }
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color(red: 0.11, green: 0.21, blue: 0.18), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
          .foregroundStyle(.white)
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
        }
        .disabled(!profileStore.draft.isReadyForOnboardingSubmission || profileStore.isSaving)
      }
      .navigationBarHidden(true)
    }
  }

  private var profileCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("What good looks like")
        .font(.headline)
      Text("The v1 assistant should recognize each person quickly, remember their stable preferences, and adapt its tone without crossing boundaries.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(18)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}

