# Workspace Contract Schema

## Purpose

This is a descriptive schema for the current NestMind monorepo. It is documentation, not a machine-validated schema file.

## Workspace Schema

```yaml
workspace:
  file: nestmind-ios-and-android.code-workspace
  folders:
    - path: .
      repo: nestmind-monorepo
      owns:
        - apps/ios/NestMind
        - apps/android
        - supabase
        - docs
        - .github/workflows
```

## Monorepo Schema

```yaml
monorepo:
  apps:
    ios:
      path: apps/ios/NestMind
      source_of_truth:
        - apps/ios/NestMind/project.yml
        - apps/ios/NestMind/Sources/**
        - apps/ios/NestMind/Config/**
        - apps/ios/NestMind/Resources/**
        - apps/ios/NestMind/README.md
    android:
      path: apps/android
      source_of_truth:
        - apps/android/app/src/main/java/com/nestmind/app/**
        - apps/android/app/src/main/AndroidManifest.xml
        - apps/android/app/build.gradle.kts
        - apps/android/settings.gradle.kts
        - apps/android/gradle/libs.versions.toml
        - apps/android/README.md
  backend:
    path: supabase
    source_of_truth:
      - supabase/migrations/20260401213000_initial_schema.sql
      - supabase/functions/api/index.ts
      - supabase/functions/_shared/**
      - supabase/config.toml
      - .env.example
  docs:
    shared:
      path: docs/shared
      owns:
        - product scope
        - backend contract
        - architecture
        - workspace ownership model
    ios:
      path: docs/ios
      owns:
        - iOS-only UI structure
    android:
      path: docs/android
      owns:
        - Android-only UI structure
        - Android parity and drift tracking
```

## Contract Rules

- shared product scope and backend contract changes should update `docs/shared` and the owning code in the same change
- platform-specific UI changes belong in `docs/ios` or `docs/android`
- Android implementation drift should be documented explicitly rather than silently redefined as contract
- the backend API remains the shared contract boundary between clients and Ollama
- the iOS Xcode project remains derived from XcodeGen

## Unspecified Areas

The current repo does not define:

- a machine-enforced schema validator for this workspace contract
- a root task runner spanning both mobile apps
- Android CI automation
