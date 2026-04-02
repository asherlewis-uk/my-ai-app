import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ConversationStore {
  private let apiClient: APIClient

  var conversation: ConversationDetail?
  var pendingAttachments: [PendingAttachment] = []
  var isLoading = false
  var isSending = false
  var errorMessage: String?

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func loadLatestConversation() async throws {
    isLoading = true
    defer { isLoading = false }

    do {
      let conversations = try await apiClient.fetchConversations(limit: 1)
      guard let latest = conversations.first else {
        conversation = nil
        return
      }
      conversation = try await apiClient.fetchConversation(id: latest.id)
    } catch {
      errorMessage = error.localizedDescription
      throw error
    }
  }

  func analyzeImageData(_ data: Data, prompt: String = "Capture the key context from this image for later conversation.") async {
    do {
      let normalized = try normalizeToJPEG(data)
      let request = MediaAnalyzeRequest(
        conversationId: conversation?.id,
        prompt: prompt,
        imageBase64: normalized.base64EncodedString(),
        contentType: "image/jpeg"
      )

      let response = try await apiClient.analyzeMedia(requestBody: request)
      pendingAttachments.append(
        PendingAttachment(
          id: response.asset.id,
          asset: response.asset,
          localLabel: response.summary
        )
      )
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func removeAttachment(id: UUID) {
    pendingAttachments.removeAll { $0.id == id }
  }

  func sendMessage(_ text: String) async {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty || !pendingAttachments.isEmpty else { return }

    isSending = true
    defer { isSending = false }

    do {
      let response = try await apiClient.sendChat(
        requestBody: ChatRequest(
          conversationId: conversation?.id,
          message: trimmed,
          mediaAssetIds: pendingAttachments.map(\.asset.id)
        )
      )
      conversation = response.conversation
      pendingAttachments = []
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func reset() {
    conversation = nil
    pendingAttachments = []
    isLoading = false
    isSending = false
    errorMessage = nil
  }

  private func normalizeToJPEG(_ data: Data) throws -> Data {
    guard let image = UIImage(data: data), let jpegData = image.jpegData(compressionQuality: 0.85) else {
      throw ConversationError.invalidImage
    }
    return jpegData
  }
}

enum ConversationError: LocalizedError {
  case invalidImage

  var errorDescription: String? {
    switch self {
    case .invalidImage:
      return "The selected image could not be processed."
    }
  }
}
