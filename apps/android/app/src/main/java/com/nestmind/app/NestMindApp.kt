package com.nestmind.app

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.*
import com.nestmind.app.features.auth.AuthScreen
import com.nestmind.app.features.chat.ChatScreen
import com.nestmind.app.features.memory.MemoryScreen
import com.nestmind.app.features.onboarding.OnboardingScreen
import com.nestmind.app.features.profile.ProfileScreen
import com.nestmind.app.features.settings.SettingsScreen
import com.nestmind.app.navigation.AppDestination
import com.nestmind.app.navigation.MainTab
import com.nestmind.app.ui.theme.NestMindTheme

@Composable
fun NestMindApp(appViewModel: AppViewModel) {
    NestMindTheme {
        val launchState by appViewModel.launchState.collectAsState()
        val bannerMessage by appViewModel.bannerMessage.collectAsState()
        val navController = rememberNavController()

        // Navigate based on launch state
        LaunchedEffect(launchState) {
            when (launchState) {
                LaunchState.SIGNED_OUT -> navController.navigate(AppDestination.Auth.route) {
                    popUpTo(0) { inclusive = true }
                    launchSingleTop = true
                }
                LaunchState.NEEDS_ONBOARDING -> navController.navigate(AppDestination.Onboarding.route) {
                    popUpTo(0) { inclusive = true }
                    launchSingleTop = true
                }
                LaunchState.READY -> navController.navigate(AppDestination.Main.route) {
                    popUpTo(0) { inclusive = true }
                    launchSingleTop = true
                }
                LaunchState.ERROR -> navController.navigate(AppDestination.Auth.route) {
                    popUpTo(0) { inclusive = true }
                    launchSingleTop = true
                }
                LaunchState.LAUNCHING,
                LaunchState.LOADING_PROFILE -> Unit // Stay on current screen
            }
        }

        Scaffold(
            snackbarHost = {
                bannerMessage?.let { msg ->
                    Snackbar(
                        action = {
                            TextButton(onClick = { appViewModel.clearBanner() }) { Text("Dismiss") }
                        }
                    ) { Text(msg) }
                }
            }
        ) { padding ->
            NavHost(
                navController = navController,
                startDestination = AppDestination.Auth.route,
                modifier = Modifier.padding(padding)
            ) {
                composable(AppDestination.Auth.route) {
                    AuthScreen(sessionViewModel = appViewModel.sessionViewModel)
                }
                composable(AppDestination.Onboarding.route) {
                    OnboardingScreen(
                        profileViewModel = appViewModel.profileViewModel,
                        onComplete = {
                            navController.navigate(AppDestination.Main.route) {
                                popUpTo(0) { inclusive = true }
                                launchSingleTop = true
                            }
                        }
                    )
                }
                composable(AppDestination.Main.route) {
                    MainScreen(appViewModel = appViewModel)
                }
            }
        }
    }
}

@Composable
fun MainScreen(appViewModel: AppViewModel) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                MainTab.all.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = MainTab.Chat.route,
            modifier = Modifier.padding(padding)
        ) {
            composable(MainTab.Chat.route) {
                ChatScreen(conversationViewModel = appViewModel.conversationViewModel)
            }
            composable(MainTab.Memory.route) {
                MemoryScreen(memoryViewModel = appViewModel.memoryViewModel)
            }
            composable(MainTab.Profile.route) {
                ProfileScreen(profileViewModel = appViewModel.profileViewModel)
            }
            composable(MainTab.Settings.route) {
                SettingsScreen(
                    sessionViewModel = appViewModel.sessionViewModel,
                    profileViewModel = appViewModel.profileViewModel
                )
            }
        }
    }
}
