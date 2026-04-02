# Android Screen Map

This document covers the Android screen and navigation structure for the shared NestMind product contract.

It is the Android platform-fit counterpart to [../ios/screen-map.md](../ios/screen-map.md), not a mirrored SwiftUI document.

## Root Flow

The Android app has three visible top-level destinations:

- `AuthScreen`
- `OnboardingScreen`
- `MainScreen`

The root gate is driven by `LaunchState` in `AppViewModel`.

Unlike the iOS app, the Android client does not currently define a dedicated launching screen. During `LAUNCHING` and `LOADING_PROFILE`, the existing root screen remains visible until navigation redirects.

## Navigation And Back Model

The checked-in Android UI map assumes:

- Jetpack Compose Navigation is the routing layer
- `NavHost` owns the active destination tree
- the navigation graph is composed from route declarations rather than custom per-screen routing code
- major screens are wrapped in Material 3 `Scaffold`
- back navigation relies on the OS-level Android back stack by default
- `BackHandler` is the sanctioned way to intercept system back when a screen needs custom back behavior
- screens should not add custom software back buttons by default

## Screen Map

### AuthScreen

Shown when:

- `launchState == SIGNED_OUT`
- `launchState == ERROR` also redirects here

Dependencies:

- `SessionViewModel`

Primary actions:

- start Google sign-in
- surface auth errors

### OnboardingScreen

Shown when:

- `launchState == NEEDS_ONBOARDING`

Dependencies:

- `ProfileViewModel`

Internal composition:

- welcome step
- identity step
- preferences step
- question step

Primary actions:

- edit onboarding draft fields
- finish onboarding

Back behavior:

- internal step controls handle form-step movement
- screen-level back should still defer to the OS back stack unless a future `BackHandler` is added for onboarding interception

### MainScreen

Shown when:

- `launchState == READY`

Tabs:

#### Chat Tab

Root screen:

- `ChatScreen`

Dependencies:

- `ConversationViewModel`

Primary actions:

- start a new conversation
- send a text message

#### Memory Tab

Root screen:

- `MemoryScreen`

Dependencies:

- `MemoryViewModel`

Primary actions:

- refresh memories
- accept memory
- reject memory
- delete memory

#### Profile Tab

Root screen:

- `ProfileScreen`

Dependencies:

- `ProfileViewModel`

Primary actions:

- edit profile draft fields
- save profile

#### Settings Tab

Root screen:

- `SettingsScreen`

Dependencies:

- `SessionViewModel`
- `ProfileViewModel`

Primary actions:

- review account summary
- sign out

## Platform-Fit Adaptations

- Android adds a dedicated `Profile` tab
- Android does not define a separate profile-editor route under `Settings`
- Android relies on system back behavior rather than rendering custom toolbar back buttons on each top-level screen

## Real Android Gaps

- Android does not include media attachment UI in chat
- Android has no checked-in memory edit screen
- Android shows the current root destination while launch state is still resolving instead of rendering a dedicated launching screen
