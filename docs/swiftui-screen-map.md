# SwiftUI Screen Map

## Root Flow

`AppRootView` selects one of four visible states:

- `LaunchingView`
- `AuthenticationView`
- `OnboardingFlowView`
- `TabView` with main product tabs

## Screen Map

### LaunchingView

Shown when:

- `launchState == .launching`
- `launchState == .loadingProfile`

Dependencies:

- none beyond `AppModel.launchState`

### AuthenticationView

Shown when:

- `launchState == .signedOut`

Dependencies:

- `SessionStore`

Primary actions:

- start Apple sign-in
- surface auth errors

### OnboardingFlowView

Shown when:

- `launchState == .needsOnboarding`

Dependencies:

- `ProfileStore`

Internal composition:

- explanatory intro text
- `profileCard`
- `ProfileFormSections`
- finish button

Primary actions:

- edit profile draft fields
- submit onboarding

### Main TabView

Shown when:

- `launchState == .ready`

Tabs:

#### Companion Tab

Container:

- `NavigationStack`

Root screen:

- `ChatView`

Dependencies:

- `ConversationStore`

Subviews:

- `EmptyChatState`
- `MessageBubble`

Primary actions:

- select photo
- remove pending attachment
- send chat message

#### Memory Tab

Container:

- `NavigationStack`

Root screen:

- `MemoryListView`

Dependencies:

- `MemoryStore`

Secondary screen:

- `MemoryEditorSheet`

Primary actions:

- open memory detail editor
- accept memory
- reject memory
- delete memory
- save memory edits

#### Settings Tab

Container:

- `NavigationStack`

Root screen:

- `SettingsView`

Dependencies:

- `ProfileStore`
- `SessionStore`

Secondary screen:

- `ProfileEditorView`

Shared form component:

- `ProfileFormSections`

Primary actions:

- review identity summary
- navigate to profile editor
- sign out

## Fields And Forms

The current shared profile form component is:

- `ProfileFormSections`

It is used in:

- onboarding
- profile editing from settings

## Not Present In Current Screen Map

- a dedicated profile tab
- a dedicated conversation list screen
- a separate media library screen
- an iPad-specific navigation layout
