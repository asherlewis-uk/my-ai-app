# Provider Strategy

## Scope

This is the current provider strategy implemented in the monorepo. It documents actual provider assignments, not desired future options.

## Current Provider Assignments

| Concern | Current Provider | Notes |
| --- | --- | --- |
| iOS client runtime | Apple iOS + SwiftUI | most complete checked-in client |
| Android client runtime | Android + Jetpack Compose | current parity gaps documented separately |
| iOS sign-in UI | Apple Sign In | surfaced through `AuthenticationServices` |
| Android sign-in UI | Google OAuth | surfaced through Supabase Auth on Android |
| auth and session backend | Supabase Auth | session token is required for product routes |
| iOS auth SDK | `supabase-swift` | used for auth session management |
| Android auth SDK | Supabase Kotlin client | used for auth session management |
| application API boundary | Supabase Edge Functions | `api` function is the product API |
| relational data | Supabase Postgres | profiles, conversations, messages, memories, feedback |
| media object storage | Supabase Storage | private `media-assets` bucket |
| inference provider | Ollama | called only from the backend |
| chat model slot | `OLLAMA_DEFAULT_MODEL` | default in `.env.example` |
| vision model slot | `OLLAMA_VISION_MODEL` | default in `.env.example` |
| memory extraction model slot | `OLLAMA_MEMORY_MODEL` | defaults to the chat model when not separately set |
| CI runner | GitHub Actions macOS runner | iOS simulator build only |

## Strategy Rules That Are Explicit In Code

- both clients talk to Supabase Auth directly for session state
- neither client talks to Ollama directly
- the Ollama API key is backend-only
- the service-role key is backend-only
- model choice is made in backend code by use case
- auth provider UX is platform-specific, but the backend auth contract remains shared

## Current Model Routing Strategy

The backend currently routes:

- normal chat to `ollamaModels.chat`
- image-backed analysis to `ollamaModels.vision`
- memory extraction to `ollamaModels.memory`

## Current Retry And Failover Strategy

The only explicitly implemented protection visible in repo code is:

- Ollama request timeout via `OLLAMA_REQUEST_TIMEOUT_MS`

The current repo does not define:

- provider failover
- multi-provider routing
- cost-based routing
- per-user model selection
- regional inference routing
