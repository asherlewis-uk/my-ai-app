# Provider Strategy

## Scope

This is the current provider strategy implemented in the repo. It documents actual provider assignments, not desired future options.

## Current Provider Assignments

| Concern | Current Provider | Notes |
| --- | --- | --- |
| native client runtime | Apple iOS + SwiftUI | iPhone-first app |
| sign-in UI | Apple Sign In | surfaced through `AuthenticationServices` |
| auth and session backend | Supabase Auth | session token is required for product routes |
| client auth SDK | `supabase-swift` | used for auth session management |
| application API boundary | Supabase Edge Functions | `api` function is the product API |
| relational data | Supabase Postgres | profiles, conversations, messages, memories, feedback |
| media object storage | Supabase Storage | private `media-assets` bucket |
| inference provider | Ollama | called only from the backend |
| chat model slot | `OLLAMA_DEFAULT_MODEL` | default `gpt-oss:20b-cloud` in `.env.example` |
| vision model slot | `OLLAMA_VISION_MODEL` | default `gemma3` in `.env.example` |
| memory extraction model slot | `OLLAMA_MEMORY_MODEL` | defaults to the chat model when not separately set |
| CI runner | GitHub Actions macOS runner | simulator build only |

## Strategy Rules That Are Explicit In Code

- the iOS app talks to Supabase Auth directly for session state
- the iOS app does not talk to Ollama directly
- the Ollama API key is backend-only
- the service-role key is backend-only
- model choice is made in backend code by use case

## Current Model Routing Strategy

The backend currently routes:

- normal chat to `ollamaModels.chat`
- image-backed analysis to `ollamaModels.vision`
- memory extraction to `ollamaModels.memory`

The route decision is hard-coded in the Edge Function logic.

The current checked-in defaults for those model slots come from `.env.example`. Runtime values are backend environment variables, not iOS app bundle configuration.

## Current Retry And Failover Strategy

The only explicitly implemented protection visible in repo code is:

- Ollama request timeout via `OLLAMA_REQUEST_TIMEOUT_MS`

The current repo does not define:

- provider failover
- multi-provider routing
- cost-based routing
- per-user model selection
- regional inference routing

Those areas are unspecified in the checked-in code.

## Why The Current Strategy Matters

The provider boundary ensures:

- the device never receives backend-only secrets
- application behavior stays behind one authenticated API surface
- model changes can happen server-side without changing client-side transport design
