# NestMind

NestMind is a greenfield SwiftUI iPhone app plus a Supabase-backed service layer for a household-aware personal AI assistant. Each person has a separate account, separate memory, and separate conversation history even if they belong to the same household container.

## What is included

- A SwiftUI iOS app scaffold with Sign in with Apple, onboarding, chat, memory review, and settings.
- A Supabase SQL migration that creates the public schema, row-level security, and storage bucket.
- A routed Supabase Edge Function that fronts Ollama and keeps the Ollama API key server-side.
- Placeholder configuration for Supabase, Ollama, bundle ID, and app naming.

## Workspace layout

- `ios/NestMind`: SwiftUI app source plus an XcodeGen manifest.
- `supabase/migrations`: database schema and policies.
- `supabase/functions`: Edge Function API plus shared helpers.
- `.env.example`: required backend environment variables.

## Setup

1. Install Xcode, XcodeGen, and the Supabase CLI on a macOS machine.
2. Update `ios/NestMind/Config/Secrets.xcconfig` with your bundle ID, Supabase URL, and publishable key.
3. Copy `.env.example` into your Supabase function environment and fill the Ollama and Supabase server-side values.
4. Apply the migration with `supabase db push`.
5. Deploy the `api` function with the Supabase CLI after loading the environment variables from `.env.example`.
6. Run `xcodegen generate` inside `ios/NestMind`.

## Constraints

This machine does not have Xcode or Swift installed, so the project is scaffolded for execution on macOS but was not built locally here.
