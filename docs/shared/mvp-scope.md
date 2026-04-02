# MVP Scope

## Scope Rule

This document reflects only the MVP surface that is verified in the current monorepo.

## In Scope

### Shared Product Contract

- authenticated use through Supabase Auth
- launch gating based on session and profile state
- onboarding backed by profile data
- profile editing and preference capture
- text chat backed by the authenticated Edge Function API
- memory review and mutation routes
- Supabase schema, RLS, storage bucket setup, and Edge Function deployment

### iOS Coverage

- Sign in with Apple
- dedicated launching screen
- photo selection and JPEG normalization on device
- server-backed media analysis before image-backed chat send
- memory edit UI
- simulator CI build on GitHub Actions

### Android Coverage

- Google OAuth sign-in
- launch routing based on session and profile state
- onboarding flow
- text chat
- memory accept, reject, and delete
- dedicated profile tab
- settings and sign-out

## Out Of Scope

- shared household memory
- shared household inference
- device-side Ollama access
- service-role usage in either client
- anonymous use without authentication
- release signing automation
- store delivery automation
- production secret storage in client configuration

## Not Present In The Current Verified Scope

- a conversation deletion route in the backend
- Android media-analysis support
- Android memory edit UI
- a checked-in Android Gradle wrapper
- a checked-in Android CI workflow
- end-to-end live verification from this Windows machine

## MVP Entry Gates

The current MVP is gated by:

- valid app configuration values
- a valid Supabase session
- a successfully loaded profile
- onboarding completion before the main experience

## MVP Exit Criteria That Are Explicitly Verified In Repo

The repo currently proves these areas by implementation:

- a signed-in user can be loaded into app state
- onboarding data can be edited and saved
- authenticated API calls exist for profile, memory, conversation, chat, and media
- iOS simulator compilation is enforced in CI

Android parity still requires follow-up in the areas listed in [../android/known-drift.md](../android/known-drift.md).
