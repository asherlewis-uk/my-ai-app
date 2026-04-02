import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
  private let apiClient: APIClient

  var profile: UserProfile?
  var draft: ProfileDraft = .empty
  var isSaving = false
  var isLoading = false
  var errorMessage: String?

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func loadProfile(seedDisplayName: String? = nil) async throws -> UserProfile {
    isLoading = true
    defer { isLoading = false }

    do {
      let loadedProfile = try await apiClient.fetchProfile()
      profile = loadedProfile
      draft = ProfileDraft(profile: loadedProfile)

      if let seedDisplayName, loadedProfile.displayName.isEmpty {
        draft.displayName = seedDisplayName
        draft.preferredName = loadedProfile.preferredName.isEmpty ? seedDisplayName : loadedProfile.preferredName
      }

      return loadedProfile
    } catch {
      errorMessage = error.localizedDescription
      throw error
    }
  }

  func saveDraft(markOnboardingComplete: Bool) async throws {
    isSaving = true
    defer { isSaving = false }

    var outgoingDraft = draft
    outgoingDraft.isOnboardingComplete = markOnboardingComplete

    do {
      let updated = try await apiClient.updateProfile(outgoingDraft.payload)
      profile = updated
      draft = ProfileDraft(profile: updated)
    } catch {
      errorMessage = error.localizedDescription
      throw error
    }
  }

  func reset() {
    profile = nil
    draft = .empty
    isSaving = false
    isLoading = false
    errorMessage = nil
  }
}

