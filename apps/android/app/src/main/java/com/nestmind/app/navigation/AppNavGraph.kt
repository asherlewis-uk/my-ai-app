package com.nestmind.app.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Top-level destinations for the application.
 */
sealed class AppDestination(val route: String) {
    object Auth : AppDestination("auth")
    object Onboarding : AppDestination("onboarding")
    object Main : AppDestination("main")
}

/**
 * Destinations within the Main (Authenticated) flow.
 */
sealed class MainTab(val route: String, val label: String, val icon: ImageVector) {
    object Chat : MainTab("chat", "Companion", Icons.Default.Chat)
    object Memory : MainTab("memory", "Memory", Icons.Default.Memory)
    object Profile : MainTab("profile", "Profile", Icons.Default.Person)
    object Settings : MainTab("settings", "Settings", Icons.Default.Settings)

    companion object {
        val all = listOf(Chat, Memory, Profile, Settings)
    }
}
