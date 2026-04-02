# Migration Summary

This file is the final handoff note for the merge from the previous split-repo setup into the current NestMind monorepo.

## What Moved

- `ios/NestMind` moved to `apps/ios/NestMind`
- the Android app moved from the sibling `nestmind-android` repo into `apps/android`
- shared docs moved from `docs/*.md` into `docs/shared/*.md`
- the iOS screen map moved from `docs/swiftui-screen-map.md` to `docs/ios/screen-map.md`
- Android repo docs were consolidated into `docs/android/` instead of remaining under the app folder

## Root Decision

- the existing `my-ai-app` repo became the monorepo root because it already owned the shared backend, shared docs, CI workflow, and the checked-in multi-platform workspace file

## Final State

- one monorepo root now owns iOS, Android, shared backend, and shared docs
- shared contracts now live under `docs/shared/`
- platform-only UI docs now live under `docs/ios/` and `docs/android/`
- the Android implementation remains intentionally documented as current-state-plus-drift rather than being presented as full parity

## What Stayed The Same

- `supabase/` remains the shared backend root
- the authenticated `api` Edge Function remains the canonical app API boundary
- the iOS app still uses XcodeGen and the same source layout inside its app folder
- the Android app still uses the same Gradle project and Compose source layout inside its app folder
- the repo still contains only the existing iOS CI workflow

## Current Platform Differences

- iOS still has the most complete checked-in implementation of the shared contract
- Android still differs in API base-path handling, response-model expectations, onboarding completion gating, launch-screen handling, and media support
- iOS uses Sign in with Apple while Android currently uses Google OAuth
- Android still has no checked-in Gradle wrapper or CI workflow

See [docs/android/known-drift.md](docs/android/known-drift.md) for the detailed parity record.

## Authoritative Handoff Files

- `README.md`
- `docs/INDEX.md`
- `docs/shared/product-definition.md`
- `docs/shared/api-contracts.md`
- `docs/shared/architecture.md`
- `docs/android/known-drift.md`

## Follow-Up Tasks

1. Decide whether to align Android to the canonical `/v1/...` API contract now or after basic post-merge validation.
2. Add a checked-in Android Gradle wrapper or document the required local Gradle version explicitly.
3. Add Android CI once the API drift and build entrypoint are stable enough to automate.
4. Consider wiring an iOS local override xcconfig if `Local.xcconfig` should remain part of the intended developer workflow.

## Known Limitations

- iOS CI proves simulator compilation only
- Android validation still depends on Android Studio or a compatible local Gradle installation
- live Supabase and Ollama verification still requires local secrets and external services
