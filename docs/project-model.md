# Project Model

## Purpose

This document describes how `my-ai-app` is modeled as a repo and as part of the checked-in workspace.

## Workspace Model

The checked-in workspace file opens two folders:

- `.` -> `C:\Users\asher\PROJECTS\my-ai-app`
- `../nestmind-android` -> sibling Android repo

Only `my-ai-app` is part of this git repository.

## Repo Ownership Model

`my-ai-app` currently owns:

- the iOS application in `ios/NestMind`
- the shared Supabase backend definition in `supabase`
- the iOS CI workflow in `.github/workflows/ios-build.yml`
- repo-level docs in `README.md`, `ios/NestMind/README.md`, and `docs/`

`my-ai-app` does not currently own:

- Android source code
- Android build tooling
- a combined multi-platform monorepo layout

## Product Model

The current product is modeled as:

- one iOS client
- one authenticated backend API layer
- one per-user assistant context
- one household membership per user in the current schema
- no shared memory or shared inference in v1

## Source Of Truth Model

The current source-of-truth files are:

- `ios/NestMind/project.yml` for iOS project structure and dependencies
- `ios/NestMind/Config/Debug.xcconfig` for the checked-in debug config chain
- `ios/NestMind/Config/Release.xcconfig` for the checked-in release config chain
- `ios/NestMind/Config/Secrets.xcconfig` for the checked-in app configuration values currently included by both configs
- `ios/NestMind/Sources/**` for client behavior
- `ios/NestMind/Resources/Info.plist` for runtime config exposure
- `ios/NestMind/Resources/NestMind.entitlements` for checked-in signing capability configuration
- `supabase/migrations/20260401213000_initial_schema.sql` for schema and policies
- `supabase/functions/api/index.ts` for application API behavior
- `supabase/config.toml` for backend function configuration
- `.env.example` for backend environment variable shape
- `.github/workflows/ios-build.yml` for CI build gates
- `nestmind-ios-and-android.code-workspace` for workspace membership

## Change Surface Model

Changes in this repo currently fall into one or more of these surfaces:

- iOS client
- backend schema
- backend function logic
- CI
- documentation

The repo does not define a more formal domain or package ownership model than that.

## Documentation Model

The platform-level iOS reference lives in:

- `ios/NestMind/README.md`

The broader repo-scoped reference set created for this repo lives in:

- `docs/`

## Build Model

The iOS app is generated from XcodeGen.

That means:

- `project.yml` is the canonical project specification
- generated `.xcodeproj` output is a derived artifact

## Checked-In Config Caveat

The checked-in iOS config chain is:

- `Debug.xcconfig` -> `Secrets.xcconfig`
- `Release.xcconfig` -> `Secrets.xcconfig`

The repo also gitignores `ios/NestMind/Config/Local.xcconfig`, but that file is not referenced by the checked-in XcodeGen project or the checked-in xcconfig chain. That means the current repo contains a local-override hint in `.gitignore`, but not a wired local-override path in the active build definition.

## Delivery Model

The current delivery model proven by the repo is limited to:

- local Xcode generation and simulator build
- GitHub Actions simulator compilation

Release delivery beyond that is not yet modeled in checked-in automation.
