package com.nestmind.app.features.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nestmind.app.core.network.ApiClient
import com.nestmind.app.models.*
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ConversationState(
    val conversations: List<ConversationSummary> = emptyList(),
    val activeConversation: ConversationDetail? = null,
    val suggestedMemories: List<MemoryEntry> = emptyList(),
    val isSending: Boolean = false,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

class ConversationViewModel(private val apiClient: ApiClient) : ViewModel() {

    private val _state = MutableStateFlow(ConversationState())
    val state: StateFlow<ConversationState> = _state.asStateFlow()

    suspend fun loadLatestConversation() {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val summaries = apiClient.fetchConversations()
            _state.update { it.copy(conversations = summaries) }
            val latest = summaries.firstOrNull()
            if (latest != null) {
                val detail = apiClient.fetchConversation(latest.id)
                _state.update { it.copy(activeConversation = detail, isLoading = false) }
            } else {
                _state.update { it.copy(isLoading = false) }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            _state.update {
                it.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load conversations."
                )
            }
        }
    }

    fun sendMessage(text: String, mediaAssetIds: List<String> = emptyList()) {
        // Guard against blank messages
        if (text.isBlank()) return

        viewModelScope.launch {
            val previousConversation = _state.value.activeConversation

            _state.update { it.copy(isSending = true, errorMessage = null) }

            // Optimistically append user message
            val tempId = java.util.UUID.randomUUID().toString()
            val optimisticMsg = ChatMessage(
                id = tempId,
                role = ChatRole.USER,
                content = text
            )
            val current = _state.value.activeConversation
            val optimisticConversation = current?.copy(
                messages = current.messages + optimisticMsg
            ) ?: ConversationDetail(id = "", messages = listOf(optimisticMsg))

            _state.update { it.copy(activeConversation = optimisticConversation) }

            try {
                val response = apiClient.sendChat(
                    ChatRequest(
                        conversationId = current?.id?.ifBlank { null },
                        message = text,
                        mediaAssetIds = mediaAssetIds
                    )
                )
                _state.update {
                    it.copy(
                        activeConversation = response.conversation,
                        suggestedMemories = response.suggestedMemories,
                        isSending = false
                    )
                }
                // Refresh conversation list in background
                try {
                    val summaries = apiClient.fetchConversations()
                    _state.update { it.copy(conversations = summaries) }
                } catch (_: Exception) {
                    // Non-critical: conversation list refresh failure is acceptable
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Rollback optimistic message
                _state.update {
                    it.copy(
                        activeConversation = previousConversation,
                        isSending = false,
                        errorMessage = e.message ?: "Failed to send message."
                    )
                }
            }
        }
    }

    fun startNewConversation() {
        _state.update { it.copy(activeConversation = null, suggestedMemories = emptyList(), errorMessage = null) }
    }

    fun selectConversation(id: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val detail = apiClient.fetchConversation(id)
                _state.update { it.copy(activeConversation = detail, isLoading = false) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = e.message ?: "Failed to load conversation."
                    )
                }
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(errorMessage = null) }
    }

    fun reset() {
        _state.value = ConversationState()
    }
}
