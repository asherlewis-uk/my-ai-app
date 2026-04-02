# Implementation Plan

## Scope Of This Plan

This is a repo-state plan for the merged monorepo, not a speculative roadmap.

## Current Status

### Complete In Repo

- monorepo structure with `apps/ios`, `apps/android`, `supabase`, and `docs`
- iOS app shell, launch gates, and tab structure
- Android app shell, launch routing, and tab structure
- shared authenticated application API
- Supabase schema, RLS, storage bucket, and Edge Function
- iOS chat flow with media attachments
- shared memory review routes
- iOS simulator CI build

### Pending Environment Bring-Up

These items are explicitly required by the repo but not completed in source control:

- fill real values in `.env`
- fill real values in `apps/ios/NestMind/Config/Secrets.xcconfig`
- fill real values in `apps/android/local.properties`
- link the Supabase CLI to a real project
- push the database migration
- deploy the `api` Edge Function

### Pending Live Verification

These items are explicitly recommended by the repo but are not proven from this workspace:

- generate the Xcode project on macOS
- run the iOS app on simulator or device
- verify Sign in with Apple, onboarding, chat, memory, and photo upload on iOS
- open `apps/android` in Android Studio
- verify Google sign-in, onboarding, profile save, chat, memory actions, and sign-out on Android

### Not Yet Implemented

- Android API-contract alignment to the canonical function base and response payloads
- Android media-analysis and memory-edit parity
- a checked-in Android Gradle wrapper
- Android CI automation
- App Store and Play Store release automation

## Verified Next-Step Sequence

1. Configure backend and client environment values.
2. Link and deploy the Supabase project components.
3. Validate the iOS build on macOS.
4. Validate the Android build in Android Studio.
5. Align Android API and onboarding drift.
6. Add Android CI after the build and API path are stable.
