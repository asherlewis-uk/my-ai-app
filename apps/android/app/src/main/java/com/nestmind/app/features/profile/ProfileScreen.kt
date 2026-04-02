package com.nestmind.app.features.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(profileViewModel: ProfileViewModel) {
    val state by profileViewModel.state.collectAsState()
    val draft = state.draft

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile", fontWeight = FontWeight.SemiBold) },
                actions = {
                    TextButton(
                        onClick = { profileViewModel.saveDraft(markOnboardingComplete = true) },
                        enabled = !state.isSaving
                    ) {
                        if (state.isSaving) {
                            CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                        } else {
                            Text("Save")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Identity section
            SectionHeader("Identity")
            OutlinedTextField(
                value = draft.displayName,
                onValueChange = { if (it.length <= 100) profileViewModel.updateDraft { copy(displayName = it) } },
                label = { Text("Display Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            OutlinedTextField(
                value = draft.preferredName,
                onValueChange = { if (it.length <= 100) profileViewModel.updateDraft { copy(preferredName = it) } },
                label = { Text("Preferred Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Assistant preferences
            SectionHeader("Assistant Preferences")
            OutlinedTextField(
                value = draft.assistantTone,
                onValueChange = { if (it.length <= 100) profileViewModel.updateDraft { copy(assistantTone = it) } },
                label = { Text("Assistant Tone") },
                placeholder = { Text("e.g. Warm, Direct, Gentle") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            OutlinedTextField(
                value = draft.supportStyle,
                onValueChange = { if (it.length <= 100) profileViewModel.updateDraft { copy(supportStyle = it) } },
                label = { Text("Support Style") },
                placeholder = { Text("e.g. Coach, Listener, Advisor") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Life context
            SectionHeader("Life Context")
            OutlinedTextField(
                value = draft.lifeFocusesText,
                onValueChange = { if (it.length <= 500) profileViewModel.updateDraft { copy(lifeFocusesText = it) } },
                label = { Text("Life Focuses") },
                placeholder = { Text("Comma-separated, e.g. Health, Career, Family") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )
            OutlinedTextField(
                value = draft.likesText,
                onValueChange = { if (it.length <= 500) profileViewModel.updateDraft { copy(likesText = it) } },
                label = { Text("Likes") },
                placeholder = { Text("Things you enjoy, comma-separated") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )
            OutlinedTextField(
                value = draft.dislikesText,
                onValueChange = { if (it.length <= 500) profileViewModel.updateDraft { copy(dislikesText = it) } },
                label = { Text("Dislikes") },
                placeholder = { Text("Things to avoid, comma-separated") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )
            OutlinedTextField(
                value = draft.boundariesText,
                onValueChange = { if (it.length <= 500) profileViewModel.updateDraft { copy(boundariesText = it) } },
                label = { Text("Boundaries") },
                placeholder = { Text("Topics or behaviours to avoid, comma-separated") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )

            // Summary
            SectionHeader("Summary")
            OutlinedTextField(
                value = draft.summary,
                onValueChange = { if (it.length <= 1000) profileViewModel.updateDraft { copy(summary = it) } },
                label = { Text("About You") },
                placeholder = { Text("A brief summary NestMind uses to understand you") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3
            )

            state.errorMessage?.let { error ->
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = error,
                            modifier = Modifier.weight(1f),
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodySmall
                        )
                        IconButton(
                            onClick = { profileViewModel.clearError() },
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Dismiss", modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary
    )
    HorizontalDivider()
}
