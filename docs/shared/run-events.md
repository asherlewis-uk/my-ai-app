# Run Events

## Purpose

This document records the main runtime event flows that are directly visible in the monorepo.

It describes the canonical flow and calls out where Android still differs.

## 1. App Launch And Session Restore

1. The client app creates its top-level app model.
2. Supabase auth refresh starts.
3. The client reads the current session if one exists.
4. Session state drives the launch state.
5. After authentication, the client loads `/v1/profile`.
6. Profile state decides whether the app moves to onboarding or the main app.

Current difference:

- iOS renders a dedicated launching screen while state resolves
- Android currently keeps the existing root screen visible until navigation redirects

## 2. Sign-In

1. The user starts platform-native sign-in.
2. The client exchanges credentials with Supabase Auth.
3. Supabase returns a session token.
4. Session change triggers profile hydration and launch routing.

Platform note:

- iOS currently uses Sign in with Apple
- Android currently uses Google OAuth

## 3. Onboarding Completion

1. The client blocks onboarding completion until required fields are present.
2. The user finishes onboarding.
3. The client sends `PATCH /v1/profile` with `isOnboardingComplete = true`.
4. The app should move to the ready state only after save succeeds.

Current difference:

- iOS already waits for save success
- Android currently navigates forward before save success is confirmed

## 4. Chat Message Send

1. The user enters text or has pending attachments.
2. The client blocks empty sends.
3. The client posts `ChatRequest` to `/v1/chat`.
4. The backend persists the user message, calls Ollama, persists the assistant reply, and may extract memories.
5. The client replaces local conversation state with the returned payload.

## 5. Photo Attachment Preparation

Current checked-in implementation:

1. iOS selects image data.
2. iOS normalizes it to JPEG on-device.
3. iOS posts `MediaAnalyzeRequest` to `/v1/media/analyze`.
4. The backend uploads the bytes to Supabase Storage and runs vision analysis through Ollama.
5. The returned asset is attached to the next `/v1/chat` request.

Current difference:

- Android does not yet implement this flow

## 6. Memory Actions

### Accept Or Reject

1. The user chooses a memory action.
2. The client posts to `/v1/memories/:id/feedback`.
3. The returned memory replaces the local entry.

### Edit

1. The user opens a memory editor.
2. The client sends `PATCH /v1/memories/:id`.
3. The returned memory replaces the local entry.

Current difference:

- iOS has a checked-in edit flow
- Android does not yet have a checked-in edit UI

### Delete

1. The user requests deletion.
2. The client sends `DELETE /v1/memories/:id`.
3. The local memory is removed if the request succeeds.

## 7. Sign-Out

1. The user starts sign-out from settings.
2. The client signs out through Supabase.
3. Session change resets feature state.
4. The app returns to the signed-out flow
