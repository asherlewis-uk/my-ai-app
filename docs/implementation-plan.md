# Implementation Plan

## Scope Of This Plan

This is a repo-state plan, not a speculative roadmap. It uses only what is implemented today plus the verified next steps already present in the repo README.

## Current Status

### Complete In Repo

- iOS app shell, launch gates, and tab structure
- Sign in with Apple integration through Supabase
- onboarding and profile editing flows
- authenticated application API client
- Supabase schema, RLS, storage bucket, and Edge Function
- chat flow with optional media attachments
- memory review and mutation flows
- simulator CI build

### Pending Environment Bring-Up

These items are explicitly required by the repo but not completed in source control:

- fill real values in `.env`
- fill real values in `ios/NestMind/Config/Secrets.xcconfig`
- link the Supabase CLI to a real project
- push the database migration
- deploy the `api` Edge Function

Current checked-in config caveat:

- the active iOS build includes `Secrets.xcconfig` through `Debug.xcconfig` and `Release.xcconfig`
- `Local.xcconfig` is gitignored in the repo, but it is not wired into the checked-in build config chain
- this docs set therefore treats `Secrets.xcconfig` as the active checked-in config input and `Local.xcconfig` as an unwired repo hint, not as an active override mechanism

### Pending Live Verification

These items are explicitly recommended by the repo but are not proven from this workspace:

- generate the Xcode project on macOS
- run the app on simulator or device
- verify Sign in with Apple
- verify onboarding
- verify chat
- verify memory flows
- verify photo upload and media analysis end to end

### Not Yet Implemented

- App Store signing automation
- archive automation
- release delivery automation
- broad automated integration or UI coverage

## Verified Next-Step Sequence

1. Configure environment values for Supabase and Ollama.
2. Link and deploy the Supabase project components.
3. Generate the Xcode project on macOS.
4. Run end-to-end flow verification on iOS.

The checked-in repo does not define a further ordered step after live verification. Hardening needs are visible in the codebase and README gaps, but they are not sequenced more precisely in source.

## Exit Conditions Per Phase

### Environment Bring-Up Exit

- Supabase project is linked
- migration is applied
- `api` function is deployed
- app config values are no longer placeholders

### Live Verification Exit

- authentication succeeds
- onboarding can complete
- profile can save
- a conversation can be created
- a message can receive an assistant response
- a photo can be analyzed and attached
- memory list updates reflect assistant activity and user actions

### Hardening Exit

The current repo does not define hardening exit criteria beyond the items above. More detailed release gates are not specified in checked-in source.
