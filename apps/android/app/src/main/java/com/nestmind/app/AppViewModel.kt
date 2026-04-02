package com.nestmind.app

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nestmind.app.core.auth.SessionViewModel
import com.nestmind.app.core.auth.SupabaseService
import com.nestmind.app.core.config.AppConfig
import com.nestmind.app.core.network.ApiClient
import com.nestmind.app.features.chat.ConversationViewModel
import com.nestmind.app.features.memory.MemoryViewModel
import com.nestmind.app.features.profile.ProfileViewModel
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class LaunchState {
    LAUNCHING,
    SIGNED_OUT,
    LOADING_PROFILE,
    NEEDS_ONBOARDING,
    READY,
    ERROR
}

class AppViewModel : ViewModel() {

    val config = AppConfig.load()
    val supabaseService = SupabaseService(config)
    val sessionViewModel = SessionViewModel(supabaseService)

    private val apiClient = ApiClient(
        config = config,
        accessTokenProvider = { sessionViewModel.state.value.accessToken }
    )

    val profileViewModel = ProfileViewModel(apiClient)
    val conversationViewModel = ConversationViewModel(apiClient)
    val memoryViewModel = MemoryViewModel(apiClient)

    private val _launchState = MutableStateFlow(LaunchState.LAUNCHING)
    val launchState: StateFlow<LaunchState> = _launchState.asStateFlow()

    private val _bannerMessage = MutableStateFlow<String?>(null)
    val bannerMessage: StateFlow<String?> = _bannerMessage.asStateFlow()

    init {
        sessionViewModel.onSessionChange = { token ->
            handleSessionChange(token)
        }
        viewModelScope.launch {
            sessionViewModel.start()
        }
    }

    private fun handleSessionChange(token: String?) {
        viewModelScope.launch {
            if (token == null) {
                profileViewModel.reset()
                conversationViewModel.reset()
                memoryViewModel.reset()
                _launchState.value = LaunchState.SIGNED_OUT
                return@launch
            }

            _launchState.value = LaunchState.LOADING_PROFILE
            try {
                val profile = profileViewModel.loadProfile()

                if (profile == null) {
                    // loadProfile failed and communicated via its own state
                    _bannerMessage.value = "Could not load your profile. Please try again."
                    _launchState.value = LaunchState.ERROR
                    return@launch
                }

                // Load secondary data concurrently; failures are non-fatal
                val memoriesDeferred = async { runCatching { memoryViewModel.refresh() } }
                val conversationDeferred = async { runCatching { conversationViewModel.loadLatestConversation() } }

                val memoriesResult = memoriesDeferred.await()
                val conversationResult = conversationDeferred.await()

                // Log secondary failures but don't block the user
                memoriesResult.exceptionOrNull()?.let { e ->
                    Log.w("AppViewModel", "Memory load failed: ${e.message}")
                }
                conversationResult.exceptionOrNull()?.let { e ->
                    Log.w("AppViewModel", "Conversation load failed: ${e.message}")
                }

                _launchState.value = if (profile.isOnboardingComplete) LaunchState.READY else LaunchState.NEEDS_ONBOARDING
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _bannerMessage.value = "Something went wrong. Please try again."
                _launchState.value = LaunchState.ERROR
            }
        }
    }

    fun clearBanner() {
        _bannerMessage.value = null
    }

    fun retry() {
        val token = sessionViewModel.state.value.accessToken
        handleSessionChange(token)
    }

    override fun onCleared() {
        super.onCleared()
        apiClient.close()
        supabaseService.close()
    }
}
