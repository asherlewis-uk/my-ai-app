import Foundation

struct UserProfile: Codable, Equatable {
  let userId: UUID
  let householdId: UUID?
  let householdName: String?
  let householdRole: String?
  var displayName: String
  var preferredName: String
  var assistantTone: String
  var supportStyle: String
  var lifeFocuses: [String]
  var likes: [String]
  var dislikes: [String]
  var boundaries: [String]
  var onboardingAnswers: [String: String]
  var summary: String
  var isOnboardingComplete: Bool
  let createdAt: Date?
  let updatedAt: Date?
}

struct ProfileDraft: Codable, Equatable {
  var displayName: String
  var preferredName: String
  var assistantTone: String
  var supportStyle: String
  var lifeFocusesText: String
  var likesText: String
  var dislikesText: String
  var boundariesText: String
  var onboardingAnswers: [String: String]
  var summary: String
  var isOnboardingComplete: Bool

  init(
    displayName: String,
    preferredName: String,
    assistantTone: String,
    supportStyle: String,
    lifeFocusesText: String,
    likesText: String,
    dislikesText: String,
    boundariesText: String,
    onboardingAnswers: [String: String],
    summary: String,
    isOnboardingComplete: Bool
  ) {
    self.displayName = displayName
    self.preferredName = preferredName
    self.assistantTone = assistantTone
    self.supportStyle = supportStyle
    self.lifeFocusesText = lifeFocusesText
    self.likesText = likesText
    self.dislikesText = dislikesText
    self.boundariesText = boundariesText
    self.onboardingAnswers = onboardingAnswers
    self.summary = summary
    self.isOnboardingComplete = isOnboardingComplete
  }

  static let empty = ProfileDraft(
    displayName: "",
    preferredName: "",
    assistantTone: "Warm, direct, and observant.",
    supportStyle: "Coach me gently, but do not sugarcoat the truth.",
    lifeFocusesText: "",
    likesText: "",
    dislikesText: "",
    boundariesText: "",
    onboardingAnswers: [:],
    summary: "",
    isOnboardingComplete: false
  )

  init(profile: UserProfile) {
    displayName = profile.displayName
    preferredName = profile.preferredName
    assistantTone = profile.assistantTone
    supportStyle = profile.supportStyle
    lifeFocusesText = profile.lifeFocuses.joined(separator: ", ")
    likesText = profile.likes.joined(separator: ", ")
    dislikesText = profile.dislikes.joined(separator: ", ")
    boundariesText = profile.boundaries.joined(separator: ", ")
    onboardingAnswers = profile.onboardingAnswers
    summary = profile.summary
    isOnboardingComplete = profile.isOnboardingComplete
  }

  var isReadyForOnboardingSubmission: Bool {
    !preferredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !assistantTone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !supportStyle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      onboardingAnswers.values.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
  }

  var payload: ProfileUpdateRequest {
    ProfileUpdateRequest(
      displayName: displayName.trimmedOrNil,
      preferredName: preferredName.trimmedOrNil,
      assistantTone: assistantTone.trimmedOrNil,
      supportStyle: supportStyle.trimmedOrNil,
      lifeFocuses: Self.splitCSV(lifeFocusesText),
      likes: Self.splitCSV(likesText),
      dislikes: Self.splitCSV(dislikesText),
      boundaries: Self.splitCSV(boundariesText),
      onboardingAnswers: onboardingAnswers,
      summary: summary.trimmedOrNil,
      isOnboardingComplete: isOnboardingComplete
    )
  }

  static func splitCSV(_ raw: String) -> [String] {
    raw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }
}

struct ConversationSummary: Codable, Identifiable, Equatable {
  let id: UUID
  let title: String?
  let lastMessageAt: Date?
  let createdAt: Date?
}

struct ConversationDetail: Codable, Identifiable, Equatable {
  let id: UUID
  let title: String?
  let messages: [ChatMessage]
}

struct ChatMessage: Codable, Identifiable, Equatable {
  let id: UUID
  let role: ChatRole
  let content: String
  let reasoning: String?
  let createdAt: Date?
  let attachments: [MediaAsset]
}

enum ChatRole: String, Codable, CaseIterable {
  case system
  case user
  case assistant
  case tool
}

struct MemoryEntry: Codable, Identifiable, Equatable {
  let id: UUID
  var kind: MemoryKind
  var title: String
  var summary: String
  var status: MemoryStatus
  var confidence: Double
  let createdAt: Date?
  let updatedAt: Date?
  let lastReinforcedAt: Date?
}

enum MemoryKind: String, Codable, CaseIterable, Identifiable {
  case identity
  case preference
  case goal
  case routine
  case context

  var id: String { rawValue }
}

enum MemoryStatus: String, Codable, CaseIterable, Identifiable {
  case active
  case archived
  case rejected

  var id: String { rawValue }
}

enum MemoryFeedback: String, Codable, CaseIterable, Identifiable {
  case accepted
  case rejected
  case reinforced

  var id: String { rawValue }
}

struct MediaAsset: Codable, Identifiable, Equatable {
  let id: UUID
  let contentType: String
  let analysisSummary: String?
  let storagePath: String?
  let createdAt: Date?
}

struct PendingAttachment: Identifiable, Equatable {
  let id: UUID
  let asset: MediaAsset
  let localLabel: String
}

struct ChatRequest: Encodable {
  let conversationId: UUID?
  let message: String
  let mediaAssetIds: [UUID]
}

struct ChatResponse: Decodable {
  let conversation: ConversationDetail
  let profile: UserProfile?
  let suggestedMemories: [MemoryEntry]
}

struct MediaAnalyzeRequest: Encodable {
  let conversationId: UUID?
  let prompt: String
  let imageBase64: String
  let contentType: String
}

struct MediaAnalyzeResponse: Decodable {
  let asset: MediaAsset
  let summary: String
}

struct ProfileResponse: Decodable {
  let profile: UserProfile
}

struct MemoriesResponse: Decodable {
  let memories: [MemoryEntry]
}

struct ConversationsResponse: Decodable {
  let conversations: [ConversationSummary]
}

struct ConversationResponse: Decodable {
  let conversation: ConversationDetail
}

struct ProfileUpdateRequest: Encodable {
  let displayName: String?
  let preferredName: String?
  let assistantTone: String?
  let supportStyle: String?
  let lifeFocuses: [String]
  let likes: [String]
  let dislikes: [String]
  let boundaries: [String]
  let onboardingAnswers: [String: String]
  let summary: String?
  let isOnboardingComplete: Bool
}

struct MemoryUpdateRequest: Encodable {
  let kind: MemoryKind
  let title: String
  let summary: String
  let status: MemoryStatus
}

struct MemoryFeedbackRequest: Encodable {
  let feedback: MemoryFeedback
  let note: String?
}

enum OnboardingPrompt: String, CaseIterable, Identifiable {
  case whatMattersMost = "What matters most in your life right now?"
  case currentFriction = "Where are you feeling friction or overwhelm?"
  case idealSupport = "How should the assistant support you on hard days?"
  case avoidances = "What should the assistant avoid doing or saying?"
  case dailyRhythm = "What does a good day usually look like for you?"

  var id: String { rawValue }
}

extension String {
  var trimmedOrNil: String? {
    let value = trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }
}
