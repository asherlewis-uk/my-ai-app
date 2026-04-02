# NestMind iOS App

This document is the canonical platform reference for the iOS app as it exists today. It is written from the implementation in `apps/ios/NestMind`, not from product intent alone.

If Android platform docs are updated from this file later, keep the section order and subject intent the same.

Cross-platform scope-lock rule:

- preserve the same product subjects in the same high-level order
- allow platform-native documentation entrypoints and framework-specific file names where a subject mapping is recorded explicitly
- treat backend contract and product scope drift as gaps, not as platform customization

1. Product Surface
2. Repo Map
3. Architecture
4. Runtime Gates
5. Guardrails
6. Configuration
7. Backend Contract
8. Build and CI Gates
9. Change Rules

## Product Surface

The current iOS build includes:

- Sign in with Apple through Supabase Auth
- A launch gate that blocks the main app until session and profile state are known
- Profile onboarding before the user can enter the main app
- A companion chat screen with text input and photo attachment support
- Server-backed media analysis before an image becomes a chat attachment
- A memory screen for review, accept, reject, edit, and delete flows
- A settings screen for profile access and sign-out

The current main tabs are:

- `Companion`
- `Memory`
- `Settings`

There is no separate iPad layout, no landscape support, and no production archive or release automation in this repo today.

## Repo Map

```text
apps/ios/NestMind/
|- project.yml                  XcodeGen project spec
|- Config/
|  |- Debug.xcconfig
|  |- Release.xcconfig
|  |- Secrets.xcconfig         Local app configuration values
|- Resources/
|  |- Info.plist               Runtime config keys exposed to the app
|  |- NestMind.entitlements    Sign in with Apple entitlement
|  |- Assets.xcassets/
|- Sources/
|  |- App/                     App entrypoint, root container, tabs
|  |- Core/
|  |  |- Auth/                 Apple Sign-In helpers
|  |  |- Environment/          AppConfig and AppModel
|  |  |- Networking/           Edge Function client
|  |  |- Supabase/             Supabase client bootstrap
|  |- Features/
|  |  |- Auth/
|  |  |- Chat/
|  |  |- Memory/
|  |  |- Onboarding/
|  |  |- Profile/
|  |  |- Settings/
|  |- Models/                  Shared app-facing request and response models
|  |- Services/                Session, profile, memory, and conversation stores
|- Tests/NestMindTests/        Current unit tests
```

## Architecture

### App shell

`NestMindApp` owns a single `AppModel` and injects it into SwiftUI environment state. `AppRootView` is the runtime switchboard for launch, auth, onboarding, and the ready state.

The app-level launch state machine is:

- `launching`
- `signedOut`
- `loadingProfile`
- `needsOnboarding`
- `ready`

This is intentionally simple. There is one top-level model, one auth or session source of truth, and one store per product surface.

### State and data flow

The repo uses SwiftUI plus `Observation`, not MVVM with separate platform view models.

- `AppModel` composes the app and reacts to session changes
- `SessionStore` owns Supabase auth session state
- `ProfileStore` owns profile fetch or save state and the editable profile draft
- `ConversationStore` owns conversation loading, chat sending, and pending media attachments
- `MemoryStore` owns memory list refresh and mutation flows

Views bind to stores directly. Stores own async calls and error or loading state. The main rule is that views render state, while stores perform side effects.

### Backend integration

The iOS app does not call Ollama directly. All application requests flow through the authenticated Supabase Edge Function layer via `APIClient`.

- Supabase is used on-device for auth session management
- The Edge Function is used for profile, memory, chat, and media APIs
- Ollama access remains server-side only

### Navigation shape

When the app reaches `ready`, `AppRootView` mounts a `TabView` with separate `NavigationStack`s for each tab. That keeps feature navigation local while preserving one app-wide launch gate.

## Runtime Gates

The iOS app has several real gates that control whether the user can proceed.

### Configuration gate

`AppConfig.load()` requires all of these values to exist and be valid at runtime:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_FUNCTIONS_BASE_URL`

If any value is missing or malformed, app startup fails fast.

### Session gate

The main app is not reachable without a Supabase session. `SessionStore` starts auth refresh, reads the current session if one exists, and publishes auth changes back into `AppModel`.

### Profile gate

After authentication, `AppModel` loads the profile before deciding where the user lands next. Memory and conversation preloads happen after that, but profile state decides whether the app can proceed.

### Onboarding gate

The user is routed to onboarding when `profile.isOnboardingComplete == false`.

The onboarding submission button is disabled until the draft has:

- a non-empty preferred name
- a non-empty assistant tone
- a non-empty support style
- at least one non-empty onboarding answer

### Chat send gate

The chat composer only sends when at least one of these is true:

- the message contains non-whitespace text
- there is at least one pending media attachment

### Media gate

Selected photos are normalized to JPEG on-device before upload. If the image cannot be converted, the attachment never enters the conversation flow.

### Signing gate

The repo includes the Sign in with Apple entitlement, but a valid bundle identifier and Apple team are still required for device builds, archive work, and end-to-end Apple sign-in verification.

## Guardrails

These are the implementation guardrails that should not be weakened without an explicit product and security decision.

### Product guardrails

- One signed-in user maps to one private assistant context
- Household membership exists in the data model, but memory is not shared across household members in v1
- The app is iPhone-first and portrait-only

### Security guardrails

- The app never stores or ships the Supabase service-role key
- The app never stores or ships the Ollama API key
- Model calls go through the Edge Function layer, not directly from the device
- `APIClient` requires an access token for application routes and treats missing auth as a failure case

### Architectural guardrails

- Views should not talk to Supabase or raw HTTP directly
- Feature side effects should stay in stores or infrastructure helpers
- New server routes should be added through `APIClient`, not ad hoc request code inside views
- The checked-in source of truth is `project.yml`; generated Xcode project files are not the canonical definition

### UX guardrails

- Launch, auth, and onboarding are hard gates, not dismissible suggestions
- Memory operations are explicit user actions: accept, reject, edit, or delete
- Photo handling is additive to chat, not a parallel screen

## Configuration

`Secrets.xcconfig` is the local app config entry point. `Debug.xcconfig` and `Release.xcconfig` both include it.

Required values:

```xcconfig
PRODUCT_BUNDLE_IDENTIFIER = com.example.nestmind
DEVELOPMENT_TEAM =
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY = your-supabase-publishable-key
SUPABASE_FUNCTIONS_BASE_URL = $(SUPABASE_URL)/functions/v1/api
```

Important rules:

- `SUPABASE_FUNCTIONS_BASE_URL` should point at the deployed `api` function base, not just `/functions/v1`
- The iOS app uses the publishable or anon key only
- Backend-only secrets belong in Supabase secrets or server config, never in this repo's runtime app config

`Info.plist` exposes those values into the app bundle, and `AppConfig` reads them from there at startup.

## Backend Contract

The iOS app is currently wired to these authenticated routes:

- `GET /v1/profile`
- `PATCH /v1/profile`
- `GET /v1/memories`
- `PATCH /v1/memories/:id`
- `DELETE /v1/memories/:id`
- `POST /v1/memories/:id/feedback`
- `GET /v1/conversations?limit=<n>`
- `GET /v1/conversations/:id`
- `POST /v1/chat`
- `POST /v1/media/analyze`

Contract notes:

- The app encodes request bodies in snake_case
- The backend currently accepts both snake_case and camelCase request payloads for major write routes
- The app decodes response bodies as app-facing models, including camelCase response fields
- Media attachments are uploaded only after `/v1/media/analyze` persists an asset and returns its metadata

This repo assumes the Edge Function remains the stable application API boundary. If the backend contract changes, update:

- `Sources/Models/AppModels.swift`
- `Sources/Core/Networking/APIClient.swift`
- this document

## Build and CI Gates

### Local prerequisites

- Xcode 16+
- `xcodegen`
- An Apple Developer team for device testing or archive work

### Project generation

The Xcode project is generated, not committed as the primary source of truth.

```bash
cd apps/ios/NestMind
xcodegen generate
open NestMind.xcodeproj
```

### Local compile gate

```bash
cd apps/ios/NestMind
xcodegen generate
xcodebuild \
  -project NestMind.xcodeproj \
  -scheme NestMind \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### CI gate

GitHub Actions currently enforces a simulator build gate:

- checks out the repo
- selects Xcode 16 when available on `macos-15`
- installs `xcodegen`
- generates the project
- resolves Swift package dependencies
- builds for `iphonesimulator` with signing disabled

### Current automated coverage

Current unit-test coverage is narrow. The checked-in tests validate `ProfileDraft` parsing and onboarding readiness rules.

There are not yet repo-level gates for:

- end-to-end auth verification
- live Supabase integration
- media upload verification
- snapshot or UI testing
- archive or signing verification

## Change Rules

Use these rules when changing the iOS repo.

1. Keep the launch path intact: config, session, profile, onboarding, then ready.
2. Preserve the rule that model traffic stays server-side.
3. Keep user-facing state in stores, not split across unrelated SwiftUI views.
4. Treat `project.yml` as the source of truth for project structure and dependencies.
5. Update this file when product surface, architecture, guardrails, or gates change.
6. When Android documentation is created from this file, preserve the same product subjects and high-level order. Platform-specific headings or file names may differ only when an explicit subject mapping is recorded in the cross-repo documentation schema.

## Known Gaps

These are current realities of the repo, not future guarantees.

- The app is iPhone-first and portrait-only
- Automated test coverage is light
- CI proves simulator compilation, not release readiness
- The repo depends on external Supabase and Ollama configuration to run end to end
- Release signing and App Store delivery are not yet codified here
