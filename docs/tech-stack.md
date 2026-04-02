# Tech Stack

## Client Stack

### Language And UI

- Swift
- SwiftUI
- Observation
- PhotosUI
- AuthenticationServices

### Platform Target

- iOS deployment target `17.0`
- iPhone target only
- portrait-only orientation in `Info.plist`

### Networking And Auth

- `URLSession` for authenticated application API requests
- `supabase-swift` for Supabase integration and auth session management

### Data Modeling

- `Codable`
- JSON encoder with `convertToSnakeCase`
- JSON decoder with `convertFromSnakeCase`

### Local Test Stack

- XCTest

## Backend Stack

### Platform

- Supabase

### Services Used

- Auth
- Postgres
- Storage
- Edge Functions

### Languages And Libraries

- TypeScript in Deno Edge Functions
- `@supabase/supabase-js@2`
- SQL and PL/pgSQL in migrations

### AI Integration

- Ollama over HTTP
- request path `/api/chat`

### Current Model Slots

- default chat model from `OLLAMA_DEFAULT_MODEL`
- vision model from `OLLAMA_VISION_MODEL`
- memory extraction model from `OLLAMA_MEMORY_MODEL`

## Build And Project Tooling

- XcodeGen
- Xcode 16+
- GitHub Actions
- `xcodebuild`

## Configuration Formats In Use

- `.xcconfig`
- `.env` shape via `.env.example`
- `Info.plist`
- `.toml`
- `.sql`
- `.yml`
- `.md`

## Checked-In Configuration Inputs

- `ios/NestMind/project.yml`
- `ios/NestMind/Config/Debug.xcconfig`
- `ios/NestMind/Config/Release.xcconfig`
- `ios/NestMind/Config/Secrets.xcconfig`
- `ios/NestMind/Resources/Info.plist`
- `supabase/config.toml`
- `.env.example`

The repo also gitignores `ios/NestMind/Config/Local.xcconfig`, but that file is not referenced by the checked-in XcodeGen or xcconfig chain.

## Workspace Tooling

- VS Code workspace file `nestmind-ios-and-android.code-workspace`

## Not Present In Current Stack

The current repo does not show:

- a dependency injection framework
- a local database on the client
- a separate REST server outside Supabase Edge Functions
- a cross-platform shared UI layer
