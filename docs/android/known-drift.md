# Android Known Drift

This document records the checked-in Android differences from the canonical shared NestMind contract.

Use [../shared/api-contracts.md](../shared/api-contracts.md), [../shared/onboarding.md](../shared/onboarding.md), and [../shared/run-events.md](../shared/run-events.md) as the source of truth for intended behavior.

## Allowed Platform-Fit Differences

These are documented as acceptable Android-native adaptations because they preserve product intent:

- Google OAuth instead of Apple sign-in
- a dedicated `Profile` tab instead of profile editing nested under `Settings`
- Compose Navigation and Material 3 screen shells instead of the SwiftUI container structure

## API Contract Drift

The current Android implementation still differs from the shared backend contract in these checked-in ways:

- `app/build.gradle.kts` defaults `SUPABASE_FUNCTIONS_BASE_URL` to `/functions/v1` instead of the canonical deployed `api` function base
- `core/network/ApiClient.kt` appends `api/...` segments instead of sending canonical `/v1/...` routes from the function base
- Android response models still expect several snake_case payload fields where the backend returns camelCase
- `UserProfile` in `models/AppModels.kt` requires an `id` field that the canonical profile response does not return
- `ApiClient` contains a non-canonical `deleteConversation()` method even though the backend does not expose `DELETE /v1/conversations/:id`

## Feature Drift

The current Android client is still missing:

- photo attachment preparation and `/v1/media/analyze`
- image-backed chat send
- memory edit UI

## Launch And Onboarding Drift

The current Android launch and onboarding flow still differs from the canonical contract:

- there is no dedicated launching screen while launch state resolves
- onboarding completion does not require at least one non-empty onboarding answer
- onboarding currently navigates forward immediately after starting save rather than waiting for save success

## Tooling Drift

The current Android tooling still differs from the iOS side of the monorepo:

- no checked-in Gradle wrapper
- no checked-in Android CI workflow
- no checked-in end-to-end Android verification evidence

## Lowest-Risk Follow-Up Order

1. Fix the Android function base and route-joining logic so both clients target the same canonical `/v1/...` API surface.
2. Align Android response models to the shared camelCase payload contract and remove the non-canonical conversation delete client method if it is still unused.
3. Fix onboarding completion gating and launch-screen behavior.
4. Add media-analysis and memory-edit parity only after the shared API path is stable.
5. Add Android CI after the build entrypoint and API surface are aligned.
