# Product Definition

## Product

NestMind is a greenfield, iPhone-first SwiftUI application backed by Supabase and Ollama.

The current product definition that is directly supported by the repo is:

- one private assistant per signed-in user
- profile-aware support that uses stable preferences and onboarding answers
- memory-aware chat that can surface and manage durable user-specific memories
- photo-aware conversation support through server-side media analysis
- household membership in the data model, but no shared household memory or shared inference in v1

## Current Value Proposition

The current iOS build presents NestMind as:

- a private AI companion
- tuned to each signed-in person
- backed by profile context, accepted memories, and optional photo context
- routed through a secure backend instead of direct device-to-model calls

## Verified User-Facing Surfaces

The repo currently implements:

- Sign in with Apple
- profile onboarding
- editable profile and preferences
- chat with text input
- photo selection and attachment preparation
- memory review, acceptance, rejection, editing, and deletion
- settings and sign-out

## User Model

The current repo defines the user model this way:

- authentication is per user
- each user has one profile
- each user belongs to exactly one household membership in the current schema
- household membership exists for data modeling, but the assistant remains private to the signed-in user in v1

## Product Rules That Are Explicit In The Repo

- the app is iPhone-first
- the app is portrait-only
- the main experience is gated by session state and onboarding completion
- the app does not talk to Ollama directly
- the app does not store the Ollama API key

## Current Non-Goals Or Unimplemented Areas

These are explicitly absent or not yet implemented in the current repo:

- shared household memory
- shared household inference
- direct device-side model access
- iPad-specific layout work
- landscape support
- App Store signing and release automation
- production secret management inside the client repo

## Definition Of "Good" In The Current Build

The onboarding UI defines the intended v1 behavior this way:

- the assistant should recognize each person quickly
- it should remember stable preferences
- it should adapt tone without crossing boundaries

That is the most specific checked-in statement of product quality currently present in the codebase.
