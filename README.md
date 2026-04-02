# NestMind

NestMind is a greenfield iPhone-first SwiftUI app backed by Supabase and Ollama. The current scaffold is built around a private per-user assistant with Sign in with Apple, onboarding, chat, photo input, memory review, and settings.

The production shape is:

- iOS client -> Supabase Auth/Postgres/Storage/Edge Functions -> Ollama
- one private assistant per signed-in user
- household membership in the data model, but no shared memory or shared inference in v1

## Current Product Surface

The repo currently includes:

- Sign in with Apple on iOS
- profile onboarding and editable preferences
- text chat
- photo upload plus image analysis
- memory review, feedback, edit, and delete flows
- Supabase schema with RLS policies
- Supabase Edge Function API that proxies Ollama server-side
- GitHub Actions simulator build for CI

## Repository Layout

- `ios/NestMind`: SwiftUI application, XcodeGen project spec, tests, app config, and the canonical platform doc in [ios/NestMind/README.md](ios/NestMind/README.md)
- `supabase/migrations`: Postgres schema and policies
- `supabase/functions/api`: authenticated API routes used by the iOS client
- `supabase/functions/_shared`: shared Edge Function helpers for CORS, auth, and Ollama calls
- `.github/workflows/ios-build.yml`: macOS CI build for the iOS app

## Backend API

The iOS client is wired to these authenticated routes:

- `GET /v1/profile`
- `PATCH /v1/profile`
- `GET /v1/memories`
- `PATCH /v1/memories/:id`
- `DELETE /v1/memories/:id`
- `POST /v1/memories/:id/feedback`
- `GET /v1/conversations`
- `GET /v1/conversations/:id`
- `POST /v1/chat`
- `POST /v1/media/analyze`

The Edge Function entrypoint is [index.ts](supabase/functions/api/index.ts). Ollama requests are sent through [ollama.ts](supabase/functions/_shared/ollama.ts), which keeps the Ollama API key server-side only.

## Data Model

The initial schema in [20260401213000_initial_schema.sql](supabase/migrations/20260401213000_initial_schema.sql) creates:

- `households`
- `household_memberships`
- `profiles`
- `conversations`
- `messages`
- `memory_entries`
- `media_assets`
- `memory_feedback_events`

The migration also:

- bootstraps a household and profile for each new auth user
- enables row level security
- restricts access so users can only manage their own profile, chats, memories, and media

## Required Configuration

### Supabase and Ollama env

Create a local `.env` from [.env.example](.env.example) and fill in real values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OLLAMA_BASE_URL`
- `OLLAMA_API_KEY`
- `OLLAMA_DEFAULT_MODEL`
- `OLLAMA_VISION_MODEL`
- `OLLAMA_MEMORY_MODEL`
- `OLLAMA_REQUEST_TIMEOUT_MS`

### iOS app config

Update [Secrets.xcconfig](ios/NestMind/Config/Secrets.xcconfig):

- `PRODUCT_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_FUNCTIONS_BASE_URL`

The app loads these values at runtime from [AppConfig.swift](ios/NestMind/Sources/Core/Environment/AppConfig.swift).

## Supabase Setup

Use the Supabase CLI against your real project:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set --env-file .env
supabase db push
supabase functions deploy api
```

Notes:

- `SUPABASE_SERVICE_ROLE_KEY` is backend-only. Do not put it in the iOS app config.
- The `api` function is configured with `verify_jwt = true` in [config.toml](supabase/config.toml), so client requests must include a valid Supabase access token.
- Media uploads are stored in the `media-assets` bucket created by the migration.

## iOS Setup On macOS

The project is generated from XcodeGen rather than storing a checked-in `.xcodeproj`.

Prerequisites:

- Xcode 16+
- `xcodegen`
- an Apple Developer team if you want to run on device or archive

Generate and open the project:

```bash
cd ios/NestMind
xcodegen generate
open NestMind.xcodeproj
```

Then in Xcode:

1. Select the `NestMind` target.
2. Confirm the bundle identifier and team match your Apple account.
3. Verify the Sign in with Apple capability is enabled. The entitlement already exists in [NestMind.entitlements](ios/NestMind/Resources/NestMind.entitlements).
4. Build and run on a simulator or device.

## CI Build

GitHub Actions builds the app on a hosted macOS runner using [ios-build.yml](.github/workflows/ios-build.yml). The workflow:

- runs on `macos-15`
- uses `actions/checkout@v5`
- installs `xcodegen`
- generates the Xcode project
- resolves Swift package dependencies
- builds for `iphonesimulator` with `CODE_SIGNING_ALLOWED=NO`

That CI path verifies compilation without requiring signing certificates.

## Local Build Command

If you are on macOS and only want a compile check:

```bash
cd ios/NestMind
xcodegen generate
xcodebuild \
  -project NestMind.xcodeproj \
  -scheme NestMind \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Current Limitations

This is a v1 scaffold, not a finished production app. The repo does not yet include:

- App Store signing and archive automation
- production secrets
- seeded onboarding content tailored to your final brand/voice
- runtime verification against a live Supabase and Ollama environment from this Windows machine

## Recommended Next Steps

1. Push the latest workflow change and rerun CI to confirm the build stays green without the Node 20 warning.
2. Fill real Supabase and Ollama values in `.env` and `Secrets.xcconfig`.
3. Run the migration and deploy the `api` Edge Function.
4. Generate the Xcode project on a Mac and test Sign in with Apple, onboarding, chat, memory, and photo upload end to end.
