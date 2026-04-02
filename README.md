# NestMind Monorepo

NestMind is one product with two client applications that share a single backend and contract surface:

- iOS in SwiftUI
- Android in Jetpack Compose
- Supabase Auth/Postgres/Storage/Edge Functions
- Ollama behind the authenticated Edge Function API

The monorepo keeps shared contract changes, backend changes, client changes, and documentation updates in one place so they can land atomically.

## Repository Layout

```text
.
|- apps/
|  |- ios/NestMind/           iOS app, XcodeGen project spec, tests, platform README
|  |- android/                Android app, Gradle build, platform README
|- supabase/                  schema, policies, storage config, Edge Functions
|- docs/
|  |- shared/                 canonical product, backend, architecture, and workspace docs
|  |- ios/                    iOS-only UI and platform docs
|  |- android/                Android-only UI docs and known drift
|- .github/workflows/         repo CI
|- .env.example               backend environment shape
|- MIGRATION_SUMMARY.md       merge record and follow-up list
```

## Ownership Model

- `docs/shared/` is the source of truth for shared product scope, backend contracts, and workspace structure.
- `apps/ios/NestMind` is the most complete checked-in client implementation of the shared contract.
- `apps/android` is the Android client implementation and keeps its current parity gaps documented in `docs/android/known-drift.md`.
- `supabase/` owns the shared schema, RLS, storage policies, and the authenticated `api` Edge Function.

## Canonical Shared Contract

Start here when changing behavior across platforms:

- [docs/shared/product-definition.md](docs/shared/product-definition.md)
- [docs/shared/api-contracts.md](docs/shared/api-contracts.md)
- [docs/shared/architecture.md](docs/shared/architecture.md)
- [docs/shared/backend-service-boundaries.md](docs/shared/backend-service-boundaries.md)
- [docs/shared/workspace-contract-schema.md](docs/shared/workspace-contract-schema.md)

## Known Platform Drift

The current monorepo preserves documented Android drift instead of silently claiming parity.

The main active gaps are:

- Android still targets a non-canonical function base and route-joining shape
- Android response models still differ from the shared camelCase contract
- Android onboarding completion and launch-screen behavior still differ from the canonical flow
- Android still lacks checked-in media-analysis and memory-edit support
- Android still has no checked-in Gradle wrapper or CI workflow

Use [docs/android/known-drift.md](docs/android/known-drift.md) as the authoritative drift record.

## Required Configuration

### Backend

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

### iOS

Update [apps/ios/NestMind/Config/Secrets.xcconfig](apps/ios/NestMind/Config/Secrets.xcconfig):

- `PRODUCT_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_FUNCTIONS_BASE_URL`

The app reads those values through [apps/ios/NestMind/Sources/Core/Environment/AppConfig.swift](apps/ios/NestMind/Sources/Core/Environment/AppConfig.swift).

### Android

Create `apps/android/local.properties` with:

```properties
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_FUNCTIONS_BASE_URL=https://your-project.supabase.co/functions/v1/api
```

Important note:

- the shared contract expects `SUPABASE_FUNCTIONS_BASE_URL` to target the deployed `api` function base
- the current Android implementation is still out of parity here and appends `api/...` segments internally; see [docs/android/known-drift.md](docs/android/known-drift.md)

## Shared Backend Setup

Use the Supabase CLI from the repo root:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set --env-file .env
supabase db push
supabase functions deploy api
```

Notes:

- `SUPABASE_SERVICE_ROLE_KEY` is backend-only
- the `api` function uses `verify_jwt = true` in [supabase/config.toml](supabase/config.toml)
- media uploads use the private `media-assets` bucket created by the migration

## Run Each Platform

### iOS on macOS

```bash
cd apps/ios/NestMind
xcodegen generate
open NestMind.xcodeproj
```

Compile-only check:

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

### Android

Open `apps/android` in Android Studio and let the project sync.

If a compatible local Gradle installation is available, a basic compile gate is:

```bash
gradle -p apps/android :app:assembleDebug
```

Current tooling caveat:

- the Android app does not include a checked-in Gradle wrapper
- only the iOS CI workflow is currently checked in

### Backend

The backend is managed from the repo root with the Supabase CLI. Use the setup commands in `Shared Backend Setup` above to link, push, and deploy the shared `api` function.

## Documentation Entry Points

- [docs/INDEX.md](docs/INDEX.md)
- [apps/ios/NestMind/README.md](apps/ios/NestMind/README.md)
- [apps/android/README.md](apps/android/README.md)
- [MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md)
