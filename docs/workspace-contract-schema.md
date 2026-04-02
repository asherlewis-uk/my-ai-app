# Workspace Contract Schema

## Purpose

This is a descriptive schema for the current workspace and repo contract. It is documentation, not a machine-validated schema file.

## Workspace Schema

```yaml
workspace:
  file: nestmind-ios-and-android.code-workspace
  folders:
    - path: .
      repo: my-ai-app
      owns:
        - ios application
        - shared supabase backend
        - iOS CI workflow
        - repo documentation
    - path: ../nestmind-android
      repo: nestmind-android
      owns:
        - android application
      note: referenced by workspace only; not part of this git repo
```

## my-ai-app Repo Schema

```yaml
my_ai_app:
  root_contract:
    contains:
      - ios/NestMind
      - supabase
      - .github/workflows/ios-build.yml
      - README.md
      - docs
    does_not_contain:
      - android source code
  iOS_contract:
    source_of_truth:
      - ios/NestMind/project.yml
      - ios/NestMind/Config/Debug.xcconfig
      - ios/NestMind/Config/Release.xcconfig
      - ios/NestMind/Config/Secrets.xcconfig
      - ios/NestMind/Sources/**
      - ios/NestMind/Resources/Info.plist
      - ios/NestMind/Resources/NestMind.entitlements
  backend_contract:
    source_of_truth:
      - supabase/migrations/20260401213000_initial_schema.sql
      - supabase/functions/api/index.ts
      - supabase/functions/_shared/**
      - supabase/config.toml
      - .env.example
```

## Docs Folder Schema

The requested docs set is:

```yaml
docs:
  required_files:
    - INDEX.md
    - api-contracts.md
    - architecture.md
    - backend-service-boundaries.md
    - implementation-plan.md
    - mvp-scope.md
    - onboarding.md
    - product-definition.md
    - project-model.md
    - provider-strategy.md
    - run-events.md
    - swiftui-screen-map.md
    - tech-stack.md
    - workspace-contract-schema.md
```

## Cross-Repo Documentation Lock

```yaml
cross_repo_docs_contract:
  ios_origin:
    repo: my-ai-app
    entrypoint: ios/NestMind/README.md
    section_order:
      - Product Surface
      - Repo Map
      - Architecture
      - Runtime Gates
      - Guardrails
      - Configuration
      - Backend Contract
      - Build and CI Gates
      - Change Rules
  android_support:
    repo: ../nestmind-android
    entrypoint: README.md
    documentation_mode: current_android_plus_drift
    required_subjects:
      - Product Surface
      - Repo Map
      - Architecture
      - Runtime Gates
      - Guardrails
      - Configuration
      - Backend Contract
      - Build and CI Gates
      - Change Rules
    subject_mapping:
      screen_map:
        ios_file: docs/swiftui-screen-map.md
        android_file: docs/screen-map.md
        rule: framework-specific names may differ only when they map to the same subject explicitly
```

## Contract Rules

- `my-ai-app` is the canonical repo for the iOS client in this workspace
- `my-ai-app` is also the canonical repo for the shared Supabase backend visible in this workspace
- Android is referenced by the workspace, but Android source is not part of this repo contract
- the iOS project definition is modeled by XcodeGen, not by a committed generated project as source of truth
- the active checked-in iOS config chain includes `Secrets.xcconfig`; `Local.xcconfig` is gitignored but not referenced by the checked-in build definition
- Android supporting documentation must preserve the iOS-origin product subjects and high-level section order
- Android may use platform-native entrypoints and framework-specific filenames only when an explicit subject mapping is recorded
- shared product scope and backend contract changes must originate from `my-ai-app`, not from Android docs

## Unspecified Areas

The current repo does not define:

- a machine-enforced schema validator for this workspace contract
- cross-repo documentation synchronization automation
- a mono-repo ownership model across iOS and Android
