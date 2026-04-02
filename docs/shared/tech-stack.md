# Tech Stack

## Client Stack

### iOS

- Swift
- SwiftUI
- Observation
- PhotosUI
- AuthenticationServices
- `URLSession`
- `supabase-swift`
- XCTest

### Android

- Kotlin
- Jetpack Compose
- Material 3
- StateFlow-backed view models
- Compose Navigation
- Ktor client
- kotlinx.serialization
- Supabase Kotlin client

## Backend Stack

- Supabase Auth
- Supabase Postgres
- Supabase Storage
- Supabase Edge Functions
- TypeScript in Deno Edge Functions
- `@supabase/supabase-js@2`
- SQL and PL/pgSQL migrations
- Ollama over HTTP

## Build And Project Tooling

- XcodeGen for the iOS project definition
- Gradle Kotlin DSL for Android
- GitHub Actions for the current iOS simulator build gate
- `xcodebuild`

Current tooling constraints:

- no checked-in Android Gradle wrapper
- no checked-in Android CI workflow

## Configuration Formats In Use

- `.xcconfig`
- `local.properties`
- `.env` shape via `.env.example`
- `Info.plist`
- `.toml`
- `.sql`
- `.kts`
- `.yml`
- `.md`

## Checked-In Configuration Inputs

- `apps/ios/NestMind/project.yml`
- `apps/ios/NestMind/Config/Debug.xcconfig`
- `apps/ios/NestMind/Config/Release.xcconfig`
- `apps/ios/NestMind/Config/Secrets.xcconfig`
- `apps/ios/NestMind/Resources/Info.plist`
- `apps/android/app/build.gradle.kts`
- `apps/android/gradle/libs.versions.toml`
- `supabase/config.toml`
- `.env.example`

The repo also gitignores `apps/ios/NestMind/Config/Local.xcconfig`, but that file is not referenced by the checked-in XcodeGen or xcconfig chain.

## Workspace Tooling

- VS Code workspace file `nestmind-ios-and-android.code-workspace`
