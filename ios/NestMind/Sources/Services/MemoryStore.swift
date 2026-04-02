import Foundation
import Observation

@MainActor
@Observable
final class MemoryStore {
  private let apiClient: APIClient

  var memories: [MemoryEntry] = []
  var isLoading = false
  var errorMessage: String?

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func refresh() async throws {
    isLoading = true
    defer { isLoading = false }

    do {
      memories = try await apiClient.fetchMemories()
    } catch {
      errorMessage = error.localizedDescription
      throw error
    }
  }

  func updateMemory(id: UUID, draft: MemoryUpdateRequest) async {
    do {
      let updated = try await apiClient.updateMemory(id: id, requestBody: draft)
      replace(updated)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func deleteMemory(id: UUID) async {
    do {
      try await apiClient.deleteMemory(id: id)
      memories.removeAll { $0.id == id }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func sendFeedback(id: UUID, feedback: MemoryFeedback, note: String? = nil) async {
    do {
      let updated = try await apiClient.sendMemoryFeedback(
        id: id,
        feedback: MemoryFeedbackRequest(feedback: feedback, note: note)
      )
      replace(updated)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func reset() {
    memories = []
    isLoading = false
    errorMessage = nil
  }

  private func replace(_ memory: MemoryEntry) {
    guard let index = memories.firstIndex(where: { $0.id == memory.id }) else {
      memories.insert(memory, at: 0)
      return
    }
    memories[index] = memory
  }
}

