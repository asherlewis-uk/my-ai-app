# Run Events

## Purpose

This document records the main runtime event flows that are directly visible in the current repo.

## 1. App Launch

1. `NestMindApp` creates `AppModel`.
2. `AppRootView` mounts and calls `appModel.start()`.
3. `SessionStore.start()` starts Supabase auth auto-refresh.
4. `SessionStore` tries to read the current session.
5. `SessionStore` publishes the session through `onSessionChange`.
6. `AppModel.handleSessionChange` decides the next launch state.

## 2. No Session Found

1. `SessionStore` publishes `nil`.
2. `AppModel` resets `ProfileStore`, `ConversationStore`, and `MemoryStore`.
3. `launchState` becomes `signedOut`.
4. `AppRootView` renders `AuthenticationView`.

## 3. Sign In With Apple

1. `AuthenticationView` generates a nonce.
2. The Apple sign-in request asks for `fullName` and `email`.
3. The request nonce is SHA-256 hashed.
4. On completion, the view extracts:
   - the Apple identity token
   - the display name, if present
5. `SessionStore.signInWithApple` exchanges the token with Supabase.
6. `pendingDisplayName` is saved locally.
7. `onSessionChange` fires with the new session.

## 4. Authenticated Profile Hydration

1. `AppModel` sets `launchState` to `loadingProfile`.
2. `ProfileStore.loadProfile(seedDisplayName:)` fetches `/v1/profile`.
3. If needed, `pendingDisplayName` seeds the draft display values.
4. `MemoryStore.refresh()` and `ConversationStore.loadLatestConversation()` run in parallel.
5. `AppModel` sets:
   - `needsOnboarding` if onboarding is incomplete
   - `ready` if onboarding is complete

## 5. Onboarding Completion

1. `OnboardingFlowView` enables the button only after readiness checks pass.
2. The user taps `Finish onboarding`.
3. `ProfileStore.saveDraft(markOnboardingComplete: true)` sends `PATCH /v1/profile`.
4. `onCompleted()` sets the app state to `ready`.

## 6. Chat Message Send

1. The user enters text or has pending attachments.
2. `ConversationStore.sendMessage` trims the text.
3. If both text and attachments are empty, the send is blocked.
4. The store posts `ChatRequest` to `/v1/chat`.
5. The backend:
   - ensures or creates the conversation
   - persists the user message
   - calls Ollama
   - persists the assistant reply
   - may extract memory candidates
6. The client replaces local conversation state with the returned conversation payload.
7. Pending attachments are cleared.

## 7. Photo Attachment Preparation

1. `PhotosPicker` returns image data.
2. `ConversationStore.analyzeImageData` converts it to JPEG.
3. The store posts `MediaAnalyzeRequest` to `/v1/media/analyze`.
4. The backend uploads the bytes to Supabase Storage.
5. The backend runs vision analysis through Ollama.
6. The client appends the returned asset to `pendingAttachments`.
7. The attachment is included in the next `/v1/chat` request via `mediaAssetIds`.

## 8. Memory Actions

### Accept Or Reject

1. The user swipes on a memory row.
2. `MemoryStore.sendFeedback` posts to `/v1/memories/:id/feedback`.
3. The returned memory replaces the local entry.

### Edit

1. The user opens `MemoryEditorSheet`.
2. The user saves edited values.
3. `MemoryStore.updateMemory` sends `PATCH /v1/memories/:id`.
4. The returned memory replaces the local entry.

### Delete

1. The user swipes delete.
2. `MemoryStore.deleteMemory` sends `DELETE /v1/memories/:id`.
3. The local memory is removed if the request succeeds.

## 9. Sign Out

1. The user taps `Sign out` in settings.
2. `SessionStore.signOut()` signs out through Supabase.
3. `onSessionChange(nil)` fires.
4. `AppModel` resets feature stores and returns to `signedOut`.

## Error Propagation Model

The current repo uses local store-owned error state:

- `SessionStore.errorMessage`
- `ProfileStore.errorMessage`
- `ConversationStore.errorMessage`
- `MemoryStore.errorMessage`
- `AppModel.bannerMessage`

The repo does not define a centralized analytics or telemetry event stream for these runtime events.
