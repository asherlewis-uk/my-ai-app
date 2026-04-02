package com.nestmind.app.features.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nestmind.app.core.network.ApiClient
import com.nestmind.app.models.ProfileUpdateRequest
import com.nestmind.app.models.UserProfile
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ProfileDraft(
    val displayName: String = "",
    val preferredName: String = "",
    val assistantTone: String = "",
    val supportStyle: String = "",
    val lifeFocusesText: String = "",
    val likesText: String = "",
    val dislikesText: String = "",
    val boundariesText: String = "",
    val onboardingAnswers: Map<String, String> = emptyMap(),
    val summary: String = "",
    val isOnboardingComplete: Boolean = false
) {
    companion object {
        val empty = ProfileDraft()

        fun from(profile: UserProfile) = ProfileDraft(
            displayName = profile.displayName,
            preferredName = profile.preferredName,
            assistantTone = profile.assistantTone,
            supportStyle = profile.supportStyle,
            lifeFocusesText = profile.lifeFocuses.joinToString(", "),
            likesText = profile.likes.joinToString(", "),
            dislikesText = profile.dislikes.joinToString(", "),
            boundariesText = profile.boundaries.joinToString(", "),
            onboardingAnswers = profile.onboardingAnswers,
            summary = profile.summary ?: "",
            isOnboardingComplete = profile.isOnboardingComplete
        )
    }

    val isReadyForOnboardingSubmission: Boolean
        get() = preferredName.isNotBlank() &&
                assistantTone.isNotBlank() &&
                supportStyle.isNotBlank() &&
                onboardingAnswers.values.any { it.isNotBlank() }

    fun toRequest(markOnboardingComplete: Boolean = false) = ProfileUpdateRequest(
        displayName = displayName.trimmedOrNull(),
        preferredName = preferredName.trimmedOrNull(),
        assistantTone = assistantTone.trimmedOrNull(),
        supportStyle = supportStyle.trimmedOrNull(),
        lifeFocuses = splitCsv(lifeFocusesText),
        likes = splitCsv(likesText),
        dislikes = splitCsv(dislikesText),
        boundaries = splitCsv(boundariesText),
        onboardingAnswers = onboardingAnswers,
        summary = summary.trimmedOrNull(),
        isOnboardingComplete = markOnboardingComplete
    )

    private fun String.trimmedOrNull(): String? = trim().ifBlank { null }
    private fun splitCsv(raw: String): List<String> =
        raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }
}

data class ProfileState(
    val profile: UserProfile? = null,
    val draft: ProfileDraft = ProfileDraft.empty,
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val errorMessage: String? = null
)

class ProfileViewModel(private val apiClient: ApiClient) : ViewModel() {

    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state.asStateFlow()

    suspend fun loadProfile(seedDisplayName: String? = null): UserProfile? {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        return try {
            val profile = apiClient.fetchProfile()
            val draft = ProfileDraft.from(profile).let { d ->
                if (seedDisplayName != null && profile.displayName.isEmpty())
                    d.copy(displayName = seedDisplayName, preferredName = seedDisplayName.ifBlank { d.preferredName })
                else d
            }
            _state.update { it.copy(profile = profile, draft = draft, isLoading = false) }
            profile
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            _state.update {
                it.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load profile. Please try again."
                )
            }
            null
        }
    }

    fun updateDraft(update: ProfileDraft.() -> ProfileDraft) {
        _state.update { current -> current.copy(draft = current.draft.update()) }
    }

    fun saveDraft(markOnboardingComplete: Boolean) {
        viewModelScope.launch {
            _state.update { it.copy(isSaving = true, errorMessage = null) }
            try {
                val updated = apiClient.updateProfile(_state.value.draft.toRequest(markOnboardingComplete))
                _state.update {
                    it.copy(
                        profile = updated,
                        draft = ProfileDraft.from(updated),
                        isSaving = false
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        isSaving = false,
                        errorMessage = e.message ?: "Failed to save profile. Please try again."
                    )
                }
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(errorMessage = null) }
    }

    fun reset() {
        _state.value = ProfileState()
    }
}
