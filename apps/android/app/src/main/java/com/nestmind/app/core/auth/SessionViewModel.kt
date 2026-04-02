package com.nestmind.app.core.auth

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.status.SessionStatus
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SessionState(
    val accessToken: String? = null,
    val userId: String? = null,
    val displayName: String? = null,
    val isBusy: Boolean = false,
    val errorMessage: String? = null
)

class SessionViewModel(
    private val supabaseService: SupabaseService
) : ViewModel() {

    private val _state = MutableStateFlow(SessionState())
    val state: StateFlow<SessionState> = _state.asStateFlow()

    var onSessionChange: ((String?) -> Unit)? = null

    fun start() {
        viewModelScope.launch {
            supabaseService.client.auth.sessionStatus.collect { status ->
                when (status) {
                    is SessionStatus.Authenticated -> {
                        val session = status.session
                        _state.update { current ->
                            current.copy(
                                accessToken = session.accessToken,
                                userId = session.user?.id,
                                displayName = session.user?.userMetadata
                                    ?.get("name")?.toString(),
                                isBusy = false
                            )
                        }
                        onSessionChange?.invoke(session.accessToken)
                    }
                    is SessionStatus.NotAuthenticated -> {
                        _state.value = SessionState()
                        onSessionChange?.invoke(null)
                    }
                    else -> {
                        Log.d("SessionViewModel", "Unhandled session status: $status")
                    }
                }
            }
        }
    }

    fun signInWithGoogle() {
        viewModelScope.launch {
            _state.update { it.copy(isBusy = true, errorMessage = null) }
            try {
                supabaseService.client.auth.signInWith(Google)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        errorMessage = e.message ?: "Sign-in failed. Please try again."
                    )
                }
            } finally {
                _state.update { it.copy(isBusy = false) }
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            _state.update { it.copy(isBusy = true, errorMessage = null) }
            try {
                supabaseService.client.auth.signOut()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        errorMessage = e.message ?: "Sign-out failed. Please try again."
                    )
                }
            } finally {
                _state.update { it.copy(isBusy = false) }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        onSessionChange = null
    }
}
