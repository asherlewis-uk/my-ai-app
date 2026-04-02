# Product Definition

## Product

NestMind is one product with two client applications that share a single backend contract:

- iOS in `apps/ios/NestMind`
- Android in `apps/android`
- shared backend in `supabase`

The current source of truth for intended product behavior is the shared contract plus the most complete checked-in implementation, which is currently the iOS client. Android drift is documented in [../android/known-drift.md](../android/known-drift.md).

## Shared Product Definition

The product definition directly supported by the monorepo is:

- one private assistant per signed-in user
- profile-aware support that uses stable preferences and onboarding answers
- memory-aware chat that can surface and manage durable user-specific memories
- photo-aware conversation support through server-side media analysis
- household membership in the data model, but no shared household memory or shared household inference in v1

## Current Value Proposition

NestMind is currently framed as:

- a private AI companion
- tuned to each signed-in person
- backed by profile context, accepted memories, and optional photo context
- routed through a secure backend instead of direct device-to-model calls

## Verified User-Facing Surfaces

The monorepo currently contains:

- authenticated sign-in flows on both clients
- profile onboarding
- editable profile and preferences
- text chat
- memory review and feedback flows
- settings and sign-out
- iOS-only photo attachment and media analysis support
- iOS-only checked-in memory edit UI

## User Model

The current repo defines the user model this way:

- authentication is per user
- each user has one profile
- each user belongs to exactly one household membership in the current schema
- household membership exists for data modeling, but the assistant remains private to the signed-in user in v1

## Product Rules That Are Explicit In The Repo

- the main experience is gated by session state and onboarding completion
- client apps do not call Ollama directly
- client apps do not store the Ollama API key
- client apps do not store the Supabase service-role key
- the backend contract is shared across platforms even when UI structure differs

## Current Non-Goals Or Unimplemented Areas

These are explicitly absent or not yet implemented in the checked-in monorepo:

- shared household memory
- shared household inference
- direct device-side model access
- conversation deletion from the shared backend API
- Android media-analysis and memory-edit parity
- Android CI automation
- App Store or Play Store release automation

## Definition Of "Good" In The Current Build

The onboarding UI defines the intended v1 behavior this way:

- the assistant should recognize each person quickly
- it should remember stable preferences
- it should adapt tone without crossing boundaries
