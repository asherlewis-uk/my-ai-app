# Docs Index

This folder is the canonical documentation root for the NestMind monorepo.

Use it in this order:

- `shared/` for product scope, backend contracts, architecture, and workspace ownership
- `ios/` for iOS-only UI structure and platform notes
- `android/` for Android-only UI structure and documented drift from the shared contract

## Canonical Sources

- Shared product and backend contract: [shared/product-definition.md](./shared/product-definition.md), [shared/api-contracts.md](./shared/api-contracts.md), [shared/architecture.md](./shared/architecture.md)
- Workspace and ownership model: [shared/project-model.md](./shared/project-model.md), [shared/workspace-contract-schema.md](./shared/workspace-contract-schema.md)
- iOS platform docs: [ios/INDEX.md](./ios/INDEX.md), [../apps/ios/NestMind/README.md](../apps/ios/NestMind/README.md)
- Android platform docs: [android/INDEX.md](./android/INDEX.md), [../apps/android/README.md](../apps/android/README.md)

## File Map

- [shared/product-definition.md](./shared/product-definition.md): canonical shared product definition and user model
- [shared/mvp-scope.md](./shared/mvp-scope.md): verified shared MVP scope and explicitly out-of-scope areas
- [shared/architecture.md](./shared/architecture.md): monorepo runtime and package architecture
- [shared/backend-service-boundaries.md](./shared/backend-service-boundaries.md): ownership boundaries between clients, Supabase, and Ollama
- [shared/api-contracts.md](./shared/api-contracts.md): canonical authenticated backend contract
- [shared/onboarding.md](./shared/onboarding.md): canonical onboarding fields, gates, and save behavior
- [shared/run-events.md](./shared/run-events.md): canonical runtime event flows and where Android currently differs
- [shared/provider-strategy.md](./shared/provider-strategy.md): current provider assignments and platform-specific auth choices
- [shared/tech-stack.md](./shared/tech-stack.md): current platform, backend, and tooling stack
- [shared/project-model.md](./shared/project-model.md): monorepo ownership model and canonical source files
- [shared/workspace-contract-schema.md](./shared/workspace-contract-schema.md): descriptive schema for the monorepo layout
- [shared/implementation-plan.md](./shared/implementation-plan.md): realistic follow-up sequence after the merge
- [ios/INDEX.md](./ios/INDEX.md): iOS doc entrypoint
- [android/INDEX.md](./android/INDEX.md): Android doc entrypoint and parity docs
