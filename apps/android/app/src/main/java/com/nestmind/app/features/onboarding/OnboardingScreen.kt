package com.nestmind.app.features.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.nestmind.app.features.profile.ProfileDraft
import com.nestmind.app.features.profile.ProfileViewModel
import com.nestmind.app.models.OnboardingPrompt

@Composable
fun OnboardingScreen(
    profileViewModel: ProfileViewModel,
    onComplete: () -> Unit
) {
    val state by profileViewModel.state.collectAsState()
    var step by remember { mutableIntStateOf(0) }

    val steps = listOf(
        "Welcome" to null,
        "About You" to null,
        "Your Preferences" to null,
        "Personalise" to null
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // Progress indicator
        LinearProgressIndicator(
            progress = { (step + 1).toFloat() / steps.size },
            modifier = Modifier.fillMaxWidth()
        )

        when (step) {
            0 -> WelcomeStep(
                onNext = { step++ }
            )
            1 -> AboutYouStep(
                draft = state.draft,
                onUpdate = { updatedDraft ->
                    profileViewModel.updateDraft {
                        copy(
                            displayName = updatedDraft.displayName,
                            preferredName = updatedDraft.preferredName
                        )
                    }
                },
                onNext = { step++ },
                onBack = { step-- }
            )
            2 -> PreferencesStep(
                draft = state.draft,
                onUpdate = { updatedDraft ->
                    profileViewModel.updateDraft {
                        copy(
                            assistantTone = updatedDraft.assistantTone,
                            supportStyle = updatedDraft.supportStyle
                        )
                    }
                },
                onNext = { step++ },
                onBack = { step-- }
            )
            3 -> QuestionsStep(
                draft = state.draft,
                onUpdate = { answers -> profileViewModel.updateDraft { copy(onboardingAnswers = answers) } },
                onBack = { step-- },
                onComplete = {
                    profileViewModel.saveDraft(markOnboardingComplete = true)
                    onComplete()
                },
                isSaving = state.isSaving
            )
        }

        state.errorMessage?.let { error ->
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
            ) {
                Text(
                    text = error,
                    modifier = Modifier.padding(12.dp),
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
private fun WelcomeStep(
    onNext: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Welcome to NestMind", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Text(
            "Let's set up your personal AI companion. This takes about 2 minutes.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Button(onClick = onNext, modifier = Modifier.fillMaxWidth()) {
            Text("Get Started")
            Spacer(Modifier.width(8.dp))
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null)
        }
    }
}

@Composable
private fun AboutYouStep(
    draft: ProfileDraft,
    onUpdate: (ProfileDraft) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    var displayName by remember(draft.displayName) { mutableStateOf(draft.displayName) }
    var preferredName by remember(draft.preferredName) { mutableStateOf(draft.preferredName) }

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("About You", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)

        OutlinedTextField(
            value = displayName,
            onValueChange = { displayName = it },
            label = { Text("Display Name") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )
        OutlinedTextField(
            value = preferredName,
            onValueChange = { preferredName = it },
            label = { Text("What should NestMind call you?") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(onClick = onBack, modifier = Modifier.weight(1f)) { Text("Back") }
            Button(
                onClick = {
                    onUpdate(draft.copy(displayName = displayName, preferredName = preferredName))
                    onNext()
                },
                modifier = Modifier.weight(1f),
                enabled = preferredName.isNotBlank()
            ) { Text("Next") }
        }
    }
}

@Composable
private fun PreferencesStep(
    draft: ProfileDraft,
    onUpdate: (ProfileDraft) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    var tone by remember(draft.assistantTone) { mutableStateOf(draft.assistantTone) }
    var style by remember(draft.supportStyle) { mutableStateOf(draft.supportStyle) }

    val toneOptions = listOf("Warm", "Direct", "Gentle", "Professional", "Playful")
    val styleOptions = listOf("Listener", "Coach", "Advisor", "Cheerleader", "Analyst")

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Your Preferences", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)

        Text("Preferred assistant tone", style = MaterialTheme.typography.labelLarge)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            toneOptions.forEach { option ->
                FilterChip(
                    selected = tone == option,
                    onClick = { tone = option },
                    label = { Text(option) }
                )
            }
        }

        Text("Support style", style = MaterialTheme.typography.labelLarge)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            styleOptions.forEach { option ->
                FilterChip(
                    selected = style == option,
                    onClick = { style = option },
                    label = { Text(option) }
                )
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(onClick = onBack, modifier = Modifier.weight(1f)) { Text("Back") }
            Button(
                onClick = {
                    onUpdate(draft.copy(assistantTone = tone, supportStyle = style))
                    onNext()
                },
                modifier = Modifier.weight(1f),
                enabled = tone.isNotBlank() && style.isNotBlank()
            ) { Text("Next") }
        }
    }
}

@Composable
private fun QuestionsStep(
    draft: ProfileDraft,
    onUpdate: (Map<String, String>) -> Unit,
    onBack: () -> Unit,
    onComplete: () -> Unit,
    isSaving: Boolean
) {
    val answers = remember {
        mutableStateMapOf<String, String>().apply { putAll(draft.onboardingAnswers) }
    }

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("A few more questions", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Text(
            "Help NestMind understand you better. Answer as many as you like.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        OnboardingPrompt.entries.forEach { prompt ->
            OutlinedTextField(
                value = answers[prompt.question] ?: "",
                onValueChange = { answers[prompt.question] = it },
                label = { Text(prompt.question) },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(onClick = onBack, modifier = Modifier.weight(1f)) { Text("Back") }
            Button(
                onClick = {
                    onUpdate(answers.toMap())
                    onComplete()
                },
                modifier = Modifier.weight(1f),
                enabled = !isSaving
            ) {
                if (isSaving) CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                else Text("Finish Setup")
            }
        }
    }
}
