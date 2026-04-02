# Docs Index

This folder is a scope-locked documentation set for `C:\Users\asher\PROJECTS\my-ai-app`.

All content in this folder is based on the current checked-in repo state:

- `ios/NestMind` for the iOS application
- `ios/NestMind/Config` for checked-in iOS build configuration inputs
- `supabase/migrations` for schema and RLS
- `supabase/functions` for the backend API layer
- `supabase/config.toml` for backend function configuration
- `.env.example` for backend environment variable shape
- `.github/workflows/ios-build.yml` for CI
- `nestmind-ios-and-android.code-workspace` for workspace shape

Where the repo does not specify something, the docs call that out explicitly instead of filling gaps.

## File Map

- [product-definition.md](./product-definition.md): current product definition from the current iOS build and repo README
- [mvp-scope.md](./mvp-scope.md): what is in and out of the current verified scope
- [architecture.md](./architecture.md): system and application architecture
- [backend-service-boundaries.md](./backend-service-boundaries.md): ownership boundaries between client, Supabase, and Ollama
- [api-contracts.md](./api-contracts.md): authenticated application API routes and payload contracts
- [onboarding.md](./onboarding.md): onboarding fields, gates, and save behavior
- [swiftui-screen-map.md](./swiftui-screen-map.md): current SwiftUI screen and navigation map
- [run-events.md](./run-events.md): runtime event flows from launch through sign-out
- [tech-stack.md](./tech-stack.md): languages, frameworks, tooling, and infrastructure in use
- [provider-strategy.md](./provider-strategy.md): current provider assignments and constraints
- [project-model.md](./project-model.md): how this repo is modeled inside the workspace and what it owns
- [workspace-contract-schema.md](./workspace-contract-schema.md): descriptive schema for the current workspace and docs contract
- [implementation-plan.md](./implementation-plan.md): implementation status and verified next steps

## Canonical Sources

For the iOS platform shape, the canonical repo-local source remains [ios/NestMind/README.md](../ios/NestMind/README.md).

For the iOS build definition and checked-in app configuration inputs, the canonical sources are:

- [ios/NestMind/project.yml](../ios/NestMind/project.yml)
- [ios/NestMind/Config/Debug.xcconfig](../ios/NestMind/Config/Debug.xcconfig)
- [ios/NestMind/Config/Release.xcconfig](../ios/NestMind/Config/Release.xcconfig)
- [ios/NestMind/Config/Secrets.xcconfig](../ios/NestMind/Config/Secrets.xcconfig)
- [ios/NestMind/Resources/Info.plist](../ios/NestMind/Resources/Info.plist)
- [ios/NestMind/Resources/NestMind.entitlements](../ios/NestMind/Resources/NestMind.entitlements)

For backend routes and behavior, the canonical source remains [supabase/functions/api/index.ts](../supabase/functions/api/index.ts).

For schema and RLS, the canonical source remains [supabase/migrations/20260401213000_initial_schema.sql](../supabase/migrations/20260401213000_initial_schema.sql).

For backend runtime configuration shape, the canonical sources are:

- [.env.example](../.env.example)
- [supabase/config.toml](../supabase/config.toml)
