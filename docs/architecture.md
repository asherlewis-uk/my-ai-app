# Architecture

## System Overview

The current system shape is:

```text
iOS App
  -> Supabase Auth
  -> Supabase Edge Function API
      -> Supabase Postgres
      -> Supabase Storage
      -> Ollama
```

The iOS app uses Supabase directly for authentication state and uses the Edge Function as the application API boundary for product features.

## Repo Architecture

This repo contains two major runtime surfaces:

- `ios/NestMind`: the iOS client
- `supabase`: the backend schema, storage policy, and Edge Function logic

Supporting surfaces:

- `.github/workflows/ios-build.yml`: CI build gate
- `nestmind-ios-and-android.code-workspace`: workspace shape only

## iOS Application Architecture

### App Shell

`NestMindApp` creates one `AppModel` and injects it into the SwiftUI environment.

`AppRootView` switches the app between:

- `launching`
- `signedOut`
- `loadingProfile`
- `needsOnboarding`
- `ready`

### State Ownership

The app uses `Observation` and store-style state holders rather than a separate MVVM view model layer for every screen.

Current state owners:

- `AppModel`: top-level composition and launch routing
- `SessionStore`: auth session lifecycle
- `ProfileStore`: profile fetch and save plus draft state
- `ConversationStore`: conversation loading, media preparation, and message sending
- `MemoryStore`: memory listing and memory mutations

### View Layer

Views bind directly to stores:

- `AuthenticationView`
- `OnboardingFlowView`
- `ChatView`
- `MemoryListView`
- `SettingsView`
- `ProfileEditorView`

The current screen structure is a `TabView` with a separate `NavigationStack` per tab after the app reaches `ready`.

### Networking Layer

The iOS app has two infrastructure clients:

- `SupabaseService` for auth session management
- `APIClient` for application routes under the deployed `api` Edge Function

`APIClient` uses:

- `URLSession`
- JSON encoding with `convertToSnakeCase`
- JSON decoding with `convertFromSnakeCase`
- bearer auth from the current Supabase access token

## Backend Architecture

### Edge Function

The `api` Edge Function is the application orchestrator. It currently owns:

- route parsing
- JWT-enforced access
- request validation
- profile bootstrap or lookup
- chat orchestration
- media upload orchestration
- memory extraction orchestration

### Data Layer

Supabase Postgres owns:

- user profile data
- household and membership data
- conversations and messages
- memory entries and feedback events
- media asset metadata

Supabase Storage owns:

- image bytes in the `media-assets` bucket

### Model Layer

Ollama is called only from the Edge Function.

The current backend uses separate model slots for:

- default chat
- vision analysis
- memory extraction

## Boundary Decisions

The current architecture makes these boundary decisions explicit:

- the iOS app does not call Ollama directly
- the iOS app does not hold the service-role key
- application reads and writes for product features go through the Edge Function
- the backend, not the client, decides when to call vision or memory extraction models

## Architecture Constraints

The current checked-in constraints are:

- iOS deployment target `17.0`
- Swift `5.10`
- one iPhone target plus one unit-test target
- portrait-only UI
- simulator CI build only
