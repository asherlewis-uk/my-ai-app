package com.nestmind.app.features.memory

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.ThumbDown
import androidx.compose.material.icons.filled.ThumbUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.nestmind.app.models.MemoryEntry
import com.nestmind.app.models.MemoryFeedback
import com.nestmind.app.models.MemoryKind
import com.nestmind.app.models.MemoryStatus
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemoryScreen(memoryViewModel: MemoryViewModel) {
    val state by memoryViewModel.state.collectAsState()
    val coroutineScope = rememberCoroutineScope()
    var selectedKind by remember { mutableStateOf<MemoryKind?>(null) }

    // Memoize filtered list to avoid recomputing on every recomposition
    val filtered = remember(state.memories, selectedKind) {
        if (selectedKind != null)
            state.memories.filter { it.kind == selectedKind && it.status == MemoryStatus.ACTIVE }
        else
            state.memories.filter { it.status == MemoryStatus.ACTIVE }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Memory", fontWeight = FontWeight.SemiBold) },
                actions = {
                    IconButton(
                        onClick = {
                            coroutineScope.launch {
                                memoryViewModel.refresh()
                            }
                        },
                        enabled = !state.isLoading
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Kind filter chips
            ScrollableTabRow(
                selectedTabIndex = if (selectedKind == null) 0 else MemoryKind.entries.indexOf(selectedKind) + 1,
                edgePadding = 16.dp
            ) {
                Tab(
                    selected = selectedKind == null,
                    onClick = { selectedKind = null },
                    text = { Text("All") }
                )
                MemoryKind.entries.forEach { kind ->
                    Tab(
                        selected = selectedKind == kind,
                        onClick = { selectedKind = kind },
                        text = { Text(kind.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }

            // Error banner
            state.errorMessage?.let { error ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
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
                            onClick = { memoryViewModel.clearError() },
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Dismiss", modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }

            if (state.isLoading) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (filtered.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Spacer(Modifier.height(8.dp))
                        Text("No memories yet", style = MaterialTheme.typography.titleMedium)
                        Text(
                            "NestMind will build your memory as you chat.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filtered, key = { it.id }) { memory ->
                        MemoryCard(
                            memory = memory,
                            onAccept = { memoryViewModel.sendFeedback(memory.id, MemoryFeedback.ACCEPTED) },
                            onReject = { memoryViewModel.sendFeedback(memory.id, MemoryFeedback.REJECTED) },
                            onDelete = { memoryViewModel.deleteMemory(memory.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MemoryCard(
    memory: MemoryEntry,
    onAccept: () -> Unit,
    onReject: () -> Unit,
    onDelete: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                AssistChip(
                    onClick = {},
                    label = {
                        Text(
                            memory.kind.name.lowercase().replaceFirstChar { it.uppercase() },
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                )
                Text(
                    text = "${(memory.confidence * 100).toInt()}% confidence",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Text(memory.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Text(
                memory.summary,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedIconButton(onClick = onAccept, modifier = Modifier.size(36.dp)) {
                    Icon(Icons.Default.ThumbUp, contentDescription = "Accept", modifier = Modifier.size(16.dp))
                }
                OutlinedIconButton(onClick = onReject, modifier = Modifier.size(36.dp)) {
                    Icon(Icons.Default.ThumbDown, contentDescription = "Reject", modifier = Modifier.size(16.dp))
                }
                Spacer(Modifier.weight(1f))
                OutlinedIconButton(onClick = onDelete, modifier = Modifier.size(36.dp)) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = "Delete",
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}
