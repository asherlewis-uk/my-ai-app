# Architecture

## System Overview

The current system shape is:

```text
iOS App
Android App
  -> Supabase Auth
  -> Supabase Edge Function API
      -> Supabase Postgres
      -> Supabase Storage
      -> Ollama
```

Both clients use Supabase directly for authentication state and use the authenticated Edge Function as the application API boundary for product features.

## Monorepo Architecture

This repo contains four major surfaces:

- `apps/ios/NestMind`: the iOS client
- `apps/android`: the Android client
- `supabase`: the shared backend schema, storage policy, and Edge Function logic
- `docs`: shared and platform-specific documentation

Supporting surfaces:

- `.github/workflows/ios-build.yml`: current CI build gate
- `nestmind-ios-and-android.code-workspace`: single-root workspace file

## iOS Application Architecture

The iOS app uses SwiftUI plus `Observation` with store-style state ownership:

- `AppModel`: top-level composition and launch routing
- `SessionStore`: auth session lifecycle
- `ProfileStore`: profile fetch and save plus draft state
- `ConversationStore`: conversation loading, media preparation, and message sending
- `MemoryStore`: memory listing and memory mutations

`AppRootView` switches the app between:

- `launching`
- `signedOut`
- `loadingProfile`
- `needsOnboarding`
- `ready`

## Android Application Architecture

The Android app uses Jetpack Compose plus view-model-style state ownership:

- `AppViewModel`: app-level launch flow and composition
- `SessionViewModel`: auth session lifecycle
- `ProfileViewModel`: profile loading, draft editing, and save flows
- `ConversationViewModel`: conversation loading and chat sending
- `MemoryViewModel`: memory refresh and mutation flows

Android implements the same high-level gate model, but it still has documented drift in launch-screen handling and API-path alignment.

## Backend Architecture

### Edge Function

The `api` Edge Function is the shared application orchestrator. It currently owns:

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

The current architecture makes these decisions explicit:

- neither client calls Ollama directly
- neither client holds the service-role key
- application reads and writes for product features go through the Edge Function
- the backend, not the clients, decides when to call vision or memory extraction models

## Architecture Constraints

The current checked-in constraints are:

- iOS deployment target `17.0`
- Android min SDK `26`
- portrait-only iOS UI
- iOS simulator CI build only
- Android local builds without a checked-in wrapper or CI path
