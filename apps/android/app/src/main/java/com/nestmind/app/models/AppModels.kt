package com.nestmind.app.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// ─── User Profile ────────────────────────────────────────────────────────────

@Serializable
data class UserProfile(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("household_id") val householdId: String? = null,
    @SerialName("display_name") val displayName: String = "",
    @SerialName("preferred_name") val preferredName: String = "",
    @SerialName("assistant_tone") val assistantTone: String = "",
    @SerialName("support_style") val supportStyle: String = "",
    @SerialName("life_focuses") val lifeFocuses: List<String> = emptyList(),
    val likes: List<String> = emptyList(),
    val dislikes: List<String> = emptyList(),
    val boundaries: List<String> = emptyList(),
    @SerialName("onboarding_answers") val onboardingAnswers: Map<String, String> = emptyMap(),
    val summary: String? = null,
    @SerialName("is_onboarding_complete") val isOnboardingComplete: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
data class ProfileUpdateRequest(
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("preferred_name") val preferredName: String? = null,
    @SerialName("assistant_tone") val assistantTone: String? = null,
    @SerialName("support_style") val supportStyle: String? = null,
    @SerialName("life_focuses") val lifeFocuses: List<String> = emptyList(),
    val likes: List<String> = emptyList(),
    val dislikes: List<String> = emptyList(),
    val boundaries: List<String> = emptyList(),
    @SerialName("onboarding_answers") val onboardingAnswers: Map<String, String> = emptyMap(),
    val summary: String? = null,
    @SerialName("is_onboarding_complete") val isOnboardingComplete: Boolean = false
)

// ─── Conversation & Chat ─────────────────────────────────────────────────────

@Serializable
data class ConversationSummary(
    val id: String,
    val title: String? = null,
    @SerialName("last_message_at") val lastMessageAt: String? = null,
    @SerialName("created_at") val createdAt: String? = null
)

@Serializable
data class ConversationDetail(
    val id: String,
    val title: String? = null,
    val messages: List<ChatMessage> = emptyList()
)

@Serializable
data class ChatMessage(
    val id: String,
    val role: ChatRole,
    val content: String,
    val reasoning: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    val attachments: List<MediaAsset> = emptyList()
)

@Serializable
enum class ChatRole {
    @SerialName("system") SYSTEM,
    @SerialName("user") USER,
    @SerialName("assistant") ASSISTANT,
    @SerialName("tool") TOOL
}

@Serializable
data class ChatRequest(
    @SerialName("conversation_id") val conversationId: String? = null,
    val message: String,
    @SerialName("media_asset_ids") val mediaAssetIds: List<String> = emptyList()
)

@Serializable
data class ChatResponse(
    val conversation: ConversationDetail,
    val profile: UserProfile? = null,
    @SerialName("suggested_memories") val suggestedMemories: List<MemoryEntry> = emptyList()
)

// ─── Memory ──────────────────────────────────────────────────────────────────

@Serializable
data class MemoryEntry(
    val id: String,
    val kind: MemoryKind,
    val title: String,
    val summary: String,
    val status: MemoryStatus,
    val confidence: Double = 1.0,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("last_reinforced_at") val lastReinforcedAt: String? = null
)

@Serializable
enum class MemoryKind {
    @SerialName("identity") IDENTITY,
    @SerialName("preference") PREFERENCE,
    @SerialName("goal") GOAL,
    @SerialName("routine") ROUTINE,
    @SerialName("context") CONTEXT
}

@Serializable
enum class MemoryStatus {
    @SerialName("active") ACTIVE,
    @SerialName("archived") ARCHIVED,
    @SerialName("rejected") REJECTED
}

@Serializable
enum class MemoryFeedback {
    @SerialName("accepted") ACCEPTED,
    @SerialName("rejected") REJECTED,
    @SerialName("reinforced") REINFORCED
}

@Serializable
data class MemoryUpdateRequest(
    val kind: MemoryKind,
    val title: String,
    val summary: String,
    val status: MemoryStatus
)

@Serializable
data class MemoryFeedbackRequest(
    val feedback: MemoryFeedback,
    val note: String? = null
)

// ─── Media ───────────────────────────────────────────────────────────────────

@Serializable
data class MediaAsset(
    val id: String,
    @SerialName("content_type") val contentType: String,
    @SerialName("analysis_summary") val analysisSummary: String? = null,
    @SerialName("storage_path") val storagePath: String? = null,
    @SerialName("created_at") val createdAt: String? = null
)

// ─── API Response Envelopes ──────────────────────────────────────────────────

@Serializable
data class ProfileResponse(val profile: UserProfile)

@Serializable
data class MemoriesResponse(val memories: List<MemoryEntry>)

@Serializable
data class ConversationsResponse(val conversations: List<ConversationSummary>)

@Serializable
data class ConversationResponse(val conversation: ConversationDetail)

@Serializable
data class ApiErrorEnvelope(val error: String)

// ─── Onboarding Prompts ───────────────────────────────────────────────────────

enum class OnboardingPrompt(val question: String) {
    WHAT_MATTERS_MOST("What matters most in your life right now?"),
    CURRENT_FRICTION("Where are you feeling friction or overwhelm?"),
    IDEAL_SUPPORT("How should the assistant support you on hard days?"),
    AVOIDANCES("What should the assistant avoid doing or saying?"),
    DAILY_RHYTHM("What does a good day usually look like for you?")
}
