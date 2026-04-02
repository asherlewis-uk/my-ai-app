# Backend Service Boundaries

## Purpose

This document defines which service owns which responsibilities in the current repo.

## Boundary Table

| Layer | Owns | Does Not Own |
| --- | --- | --- |
| iOS app | auth-triggering UI, local view state, profile draft editing, JPEG normalization before upload, authenticated API requests | direct Ollama access, service-role access, direct product-surface database writes |
| Supabase Auth | user session issuance and validation | product profile logic, chat orchestration, memory extraction |
| Edge Function `api` | authenticated product API, route validation, orchestration across profile, memory, media, conversation, and Ollama | native UI state, Apple sign-in UI, direct client rendering |
| Supabase Postgres | durable application data and RLS-backed persistence | model inference |
| Supabase Storage | binary media storage in `media-assets` | profile or conversation business logic |
| Ollama | chat, vision, and memory-extraction inference | auth, storage, RLS, route validation |

## Client Boundary Rules

The current client is allowed to:

- manage Supabase auth session state
- send authenticated requests to the Edge Function
- prepare image data for upload by converting selected photos to JPEG
- render profile, conversation, memory, and settings UI

The current client is not allowed to:

- access the Ollama API key
- access the Supabase service-role key
- call Ollama directly
- bypass the Edge Function for product routes

## Edge Function Boundary Rules

The current `api` function is responsible for:

- requiring an Authorization header
- validating the Supabase user from the bearer token
- loading or bootstrapping the user's profile
- enforcing conversation ownership checks
- persisting and linking media assets
- assembling the system prompt for chat
- calling Ollama
- converting database rows into app-facing response payloads

## Supabase Boundary Rules

### Auth

- validates user session tokens
- provides the user identity used by the Edge Function

### Postgres

- stores application records
- enforces row-level security policies
- bootstraps user profile and household records on auth user creation

### Storage

- stores image bytes in a private bucket
- restricts access to paths scoped by auth user id

## Ollama Boundary Rules

The current backend uses Ollama only for:

- main chat generation
- image analysis
- memory candidate extraction

The current repo does not define:

- provider failover
- model routing by tenant
- multi-provider inference support

Those areas are unspecified in the checked-in code.
