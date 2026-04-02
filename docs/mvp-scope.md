# MVP Scope

## Scope Rule

This document reflects only the MVP surface that is verified in the current repo.

## In Scope

### Client

- Sign in with Apple through Supabase Auth
- launch gating based on session and profile state
- onboarding flow backed by profile data
- companion chat screen
- text message send flow
- photo selection and JPEG normalization on device
- server-backed media analysis before image-backed chat send
- memory list and memory editor
- memory accept, reject, and delete actions
- settings screen and sign-out

### Backend

- Supabase schema, RLS, and storage bucket setup
- authenticated Edge Function API
- profile, memory, conversation, chat, and media routes
- server-side Ollama calls for chat, vision, and memory extraction

### Build And Tooling

- XcodeGen project definition
- simulator CI build on GitHub Actions
- unit tests for `ProfileDraft` parsing and onboarding readiness rules

## Out Of Scope

- shared household memory
- shared household inference
- device-side Ollama access
- service-role usage in the client
- anonymous product usage without authentication
- iPad-specific UI
- landscape support
- release signing automation
- App Store packaging and submission automation
- production secret storage in this client repo
- live end-to-end validation from this Windows machine

## Not Present In The Current Verified Scope

- a conversation deletion route in the backend
- snapshot tests
- UI tests
- release pipeline gates beyond simulator compilation
- Android source code inside this git repo

## MVP Entry Gates

The current MVP is gated by:

- valid app configuration values
- a valid Supabase session
- a successfully loaded profile
- onboarding completion before the main tab experience

## MVP Exit Criteria That Are Explicitly Verified In Repo

The repo currently proves these areas by implementation:

- a signed-in user can be loaded into app state
- onboarding data can be edited and saved
- authenticated API calls exist for profile, memory, conversation, chat, and media
- simulator compilation is enforced in CI

Anything beyond that should be treated as not yet proven by this repo alone.
