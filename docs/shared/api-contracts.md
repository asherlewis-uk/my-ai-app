# API Contracts

## Contract Scope

This document covers the authenticated product API exposed by `supabase/functions/api/index.ts` and consumed by:

- `apps/ios/NestMind/Sources/Core/Networking/APIClient.swift`
- `apps/android/app/src/main/java/com/nestmind/app/core/network/ApiClient.kt`

The iOS client is currently aligned to this contract. Android drift is documented in [../android/known-drift.md](../android/known-drift.md).

## Global Rules

- base path is the deployed `api` function base plus `/v1/...`
- JWT verification is enabled for the `api` function
- requests use `Authorization: Bearer <supabase-access-token>`
- request content type is JSON
- write routes accept snake_case request bodies and currently tolerate camelCase where helper readers are used
- responses are JSON with app-facing camelCase keys

Config source notes:

- iOS reads `SUPABASE_FUNCTIONS_BASE_URL` through its xcconfig and `Info.plist` chain
- Android reads `SUPABASE_FUNCTIONS_BASE_URL` through Gradle properties and `BuildConfig`
- JWT enforcement for the `api` function is configured in `supabase/config.toml`

## Shared Entity Shapes

### UserProfile

Fields currently returned by the backend:

- `userId`
- `householdId`
- `householdName`
- `householdRole`
- `displayName`
- `preferredName`
- `assistantTone`
- `supportStyle`
- `lifeFocuses`
- `likes`
- `dislikes`
- `boundaries`
- `onboardingAnswers`
- `summary`
- `isOnboardingComplete`
- `createdAt`
- `updatedAt`

### ConversationSummary

- `id`
- `title`
- `lastMessageAt`
- `createdAt`

### ConversationDetail

- `id`
- `title`
- `messages`

### ChatMessage

- `id`
- `role`
- `content`
- `reasoning`
- `createdAt`
- `attachments`

### MemoryEntry

- `id`
- `kind`
- `title`
- `summary`
- `status`
- `confidence`
- `createdAt`
- `updatedAt`
- `lastReinforcedAt`

### MediaAsset

- `id`
- `contentType`
- `analysisSummary`
- `storagePath`
- `createdAt`

## Routes

### GET /v1/profile

Auth required: yes

Response:

```json
{
  "profile": {
    "userId": "uuid",
    "householdId": "uuid or null",
    "householdName": "string or null",
    "householdRole": "string or null",
    "displayName": "string",
    "preferredName": "string",
    "assistantTone": "string",
    "supportStyle": "string",
    "lifeFocuses": ["string"],
    "likes": ["string"],
    "dislikes": ["string"],
    "boundaries": ["string"],
    "onboardingAnswers": { "question": "answer" },
    "summary": "string",
    "isOnboardingComplete": true,
    "createdAt": "iso8601 or null",
    "updatedAt": "iso8601 or null"
  }
}
```

Behavior notes:

- ensures a profile exists before returning
- may bootstrap a profile and household if the profile is missing

### PATCH /v1/profile

Auth required: yes

Accepted fields:

- `display_name` or `displayName`
- `preferred_name` or `preferredName`
- `assistant_tone` or `assistantTone`
- `support_style` or `supportStyle`
- `life_focuses` or `lifeFocuses`
- `likes`
- `dislikes`
- `boundaries`
- `onboarding_answers` or `onboardingAnswers`
- `summary`
- `is_onboarding_complete` or `isOnboardingComplete`

Response:

- same envelope as `GET /v1/profile`

### GET /v1/memories

Auth required: yes

Response:

```json
{
  "memories": [
    {
      "id": "uuid",
      "kind": "identity|preference|goal|routine|context",
      "title": "string",
      "summary": "string",
      "status": "active|archived|rejected",
      "confidence": 0.5,
      "createdAt": "iso8601",
      "updatedAt": "iso8601",
      "lastReinforcedAt": "iso8601"
    }
  ]
}
```

### PATCH /v1/memories/:id

Auth required: yes

Request body:

- `kind`
- `title`
- `summary`
- `status`

Response:

- one `MemoryEntry`

### DELETE /v1/memories/:id

Auth required: yes

Response:

```json
{}
```

### POST /v1/memories/:id/feedback

Auth required: yes

Request body:

- `feedback`: `accepted`, `rejected`, or `reinforced`
- `note`: optional string

Response:

- one updated `MemoryEntry`

Validation notes:

- invalid feedback values return `400`
- missing or non-owned memory returns `404`

### GET /v1/conversations?limit=<n>

Auth required: yes

Query params:

- `limit`: backend clamps to `1...20`, default `1`

Response:

```json
{
  "conversations": [
    {
      "id": "uuid",
      "title": "string or null",
      "lastMessageAt": "iso8601 or null",
      "createdAt": "iso8601 or null"
    }
  ]
}
```

### GET /v1/conversations/:id

Auth required: yes

Response:

```json
{
  "conversation": {
    "id": "uuid",
    "title": "string or null",
    "messages": [
      {
        "id": "uuid",
        "role": "system|user|assistant|tool",
        "content": "string",
        "reasoning": "string or null",
        "createdAt": "iso8601 or null",
        "attachments": [
          {
            "id": "uuid",
            "contentType": "string",
            "analysisSummary": "string or null",
            "storagePath": "string or null",
            "createdAt": "iso8601 or null"
          }
        ]
      }
    ]
  }
}
```

### POST /v1/media/analyze

Auth required: yes

Request body:

- `conversation_id` or `conversationId`: optional UUID
- `prompt`: optional string
- `image_base64` or `imageBase64`: required string
- `content_type` or `contentType`: required string

Validation notes:

- only `image/jpeg` and `image/png` are accepted
- if `conversationId` is present, conversation ownership is enforced

Response:

```json
{
  "asset": {
    "id": "uuid",
    "contentType": "image/jpeg|image/png",
    "analysisSummary": "string",
    "storagePath": "string",
    "createdAt": "iso8601"
  },
  "summary": "string"
}
```

### POST /v1/chat

Auth required: yes

Request body:

- `conversation_id` or `conversationId`: optional UUID
- `message`: string
- `media_asset_ids` or `mediaAssetIds`: array of UUIDs

Validation notes:

- the backend requires either non-empty `message` or at least one media asset id
- if no conversation id is supplied, a conversation is created
- media assets must belong to the signed-in user

Response:

```json
{
  "conversation": { "id": "uuid", "title": "string", "messages": [] },
  "profile": { "userId": "uuid" },
  "suggestedMemories": []
}
```

## Error Envelope

Non-success responses use:

```json
{
  "error": "message"
}
```

## Unsupported Or Unimplemented Product Routes

The current backend does not implement a conversation deletion route.
