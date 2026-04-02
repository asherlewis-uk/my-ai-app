# Project Model

## Purpose

This document describes how the NestMind monorepo is modeled after the merge.

## Workspace Model

The checked-in workspace file opens the monorepo root:

- `.` -> `NestMind monorepo`

## Repo Ownership Model

The monorepo currently owns:

- the iOS application in `apps/ios/NestMind`
- the Android application in `apps/android`
- the shared Supabase backend in `supabase`
- the current iOS CI workflow in `.github/workflows/ios-build.yml`
- shared and platform docs in `docs/`

## Product Model

The current product is modeled as:

- one shared backend contract
- one iOS client
- one Android client
- one private assistant context per signed-in user
- one household membership per user in the current schema
- no shared memory or shared inference in v1

## Source Of Truth Model

The current source-of-truth files are:

- `docs/shared/product-definition.md`
- `docs/shared/api-contracts.md`
- `docs/shared/architecture.md`
- `apps/ios/NestMind/project.yml`
- `apps/ios/NestMind/Sources/**`
- `apps/android/app/src/main/java/com/nestmind/app/**`
- `supabase/migrations/20260401213000_initial_schema.sql`
- `supabase/functions/api/index.ts`
- `supabase/config.toml`
- `.env.example`

## Change Surface Model

Changes in this repo currently fall into one or more of these surfaces:

- iOS client
- Android client
- backend schema
- backend function logic
- CI
- documentation

## Build Model

- the iOS app is generated from XcodeGen
- the Android app is a standard Gradle Android application project
- generated Xcode project output remains derived
- Android local builds currently depend on Android Studio or a compatible local Gradle installation

## Checked-In Config Caveats

- the active iOS build includes `Secrets.xcconfig` through `Debug.xcconfig` and `Release.xcconfig`
- `Local.xcconfig` is still gitignored, but it is not wired into the checked-in iOS config chain
- Android expects local Gradle properties in `apps/android/local.properties`
- Android still has no checked-in Gradle wrapper

## Delivery Model

The current delivery model proven by the repo is limited to:

- local Xcode generation and iOS simulator build
- local Android Studio sync and debug builds
- GitHub Actions simulator compilation for iOS
