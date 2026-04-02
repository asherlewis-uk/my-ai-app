# NestMind Android App

This document is the platform entrypoint for the Android client inside the NestMind monorepo.

Shared product scope, backend contracts, and workspace ownership now live in:

- [../../docs/shared/product-definition.md](../../docs/shared/product-definition.md)
- [../../docs/shared/api-contracts.md](../../docs/shared/api-contracts.md)
- [../../docs/shared/architecture.md](../../docs/shared/architecture.md)
- [../../docs/shared/workspace-contract-schema.md](../../docs/shared/workspace-contract-schema.md)

Android-only UI structure and parity notes live in:

- [../../docs/android/INDEX.md](../../docs/android/INDEX.md)
- [../../docs/android/screen-map.md](../../docs/android/screen-map.md)
- [../../docs/android/known-drift.md](../../docs/android/known-drift.md)

## Current Android Product Surface

The checked-in Android app currently implements:

- Google OAuth sign-in through Supabase Auth
- app-level launch routing driven by session and profile state
- onboarding flow for identity, preferences, and onboarding answers
- text chat with optimistic user-message send
- memory review with accept, reject, and delete actions
- dedicated profile editing in a `Profile` tab
- settings with account summary and sign-out

## Platform-Fit Adaptations

These differences from the iOS client are documented as acceptable Android-native adaptations because they preserve product intent:

- Google OAuth instead of Apple sign-in
- dedicated `Profile` tab instead of nesting profile editing under `Settings`
- Jetpack Compose Navigation and Material 3 `Scaffold` instead of SwiftUI navigation containers

## Known Gaps

Real Android gaps against the shared contract are tracked in [../../docs/android/known-drift.md](../../docs/android/known-drift.md).

The largest current gaps are:

- no photo attachment flow
- no `/v1/media/analyze` client path
- no checked-in memory edit UI
- function-base and route-joining drift from the canonical shared `/v1/...` API contract
- response-model drift from canonical camelCase response payloads
- onboarding completion does not enforce the full canonical completion gate and navigates forward before save success is confirmed
- no dedicated launching screen while launch state is still resolving

## Configuration

The checked-in Android build reads these values through Gradle properties and exposes them through `BuildConfig`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_FUNCTIONS_BASE_URL`

Local overrides normally live in `apps/android/local.properties`, which is gitignored.

Canonical shared-contract example:

```properties
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_FUNCTIONS_BASE_URL=https://your-project.supabase.co/functions/v1/api
```

The Android OAuth redirect URI is:

- `nestmind://auth-callback`

## Local Setup

1. Create or edit `apps/android/local.properties`.
2. Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_FUNCTIONS_BASE_URL`.
3. In Supabase Auth, enable Google and register the Android OAuth client.
4. Add `nestmind://auth-callback` to the Supabase redirect URL allowlist.
5. Open `apps/android` in Android Studio and let the IDE sync the Gradle project.

## Build And Verification

### Local prerequisites

- Android Studio with a compatible AGP/Kotlin environment
- Android SDK 35
- Java 17
- IDE-managed Gradle sync or a compatible local Gradle installation

Current tooling note:

- the repo does not currently include a checked-in Gradle wrapper

### Local compile gate

The checked-in Android app supports local IDE builds for:

- debug builds
- emulator or device testing on API 26+

### Manual verification targets

The current Android app should be verified for:

- sign-in
- onboarding routing
- profile save
- text chat request and response
- memory accept, reject, and delete actions
- sign-out

Not currently available to verify in Android:

- photo attachment and media analysis
- memory edit UI

### CI and automated coverage

The monorepo does not currently contain a checked-in Android CI workflow.
