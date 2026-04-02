package com.nestmind.app.features.memory

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

data class MemoryState(
    val memories: List<MemoryEntry> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

class MemoryViewModel(private val apiClient: ApiClient) : ViewModel() {

    private val _state = MutableStateFlow(MemoryState())
    val state: StateFlow<MemoryState> = _state.asStateFlow()

    suspend fun refresh() {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val memories = apiClient.fetchMemories()
            _state.update { it.copy(memories = memories, isLoading = false) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            _state.update {
                it.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load memories."
                )
            }
            // Do NOT rethrow — error is communicated via state
        }
    }

    fun updateMemory(id: String, draft: MemoryUpdateRequest) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val updated = apiClient.updateMemory(id, draft)
                replace(updated)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(errorMessage = e.message ?: "Failed to update memory.")
                }
            } finally {
                _state.update { it.copy(isLoading = false) }
            }
        }
    }

    fun deleteMemory(id: String) {
        viewModelScope.launch {
            _state.update { it.copy(errorMessage = null) }
            try {
                apiClient.deleteMemory(id)
                _state.update { current ->
                    current.copy(memories = current.memories.filter { it.id != id })
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(errorMessage = e.message ?: "Failed to delete memory.")
                }
            }
        }
    }

    fun sendFeedback(id: String, feedback: MemoryFeedback, note: String? = null) {
        viewModelScope.launch {
            _state.update { it.copy(errorMessage = null) }
            try {
                val updated = apiClient.sendMemoryFeedback(id, MemoryFeedbackRequest(feedback, note))
                replace(updated)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(errorMessage = e.message ?: "Failed to send feedback.")
                }
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(errorMessage = null) }
    }

    fun reset() {
        _state.value = MemoryState()
    }

    private fun replace(memory: MemoryEntry) {
        _state.update { current ->
            val list = current.memories.toMutableList()
            val index = list.indexOfFirst { it.id == memory.id }
            if (index >= 0) list[index] = memory else list.add(0, memory)
            current.copy(memories = list)
        }
    }
}
