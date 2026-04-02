# Onboarding

## Purpose

The current onboarding flow teaches NestMind how to help a specific signed-in user before the main app becomes available.

The UI explicitly frames onboarding as collecting:

- stable facts
- preferences
- desired support style
- durable context that should shape future responses

## Entry Condition

The app routes to onboarding when:

- the user is authenticated
- the profile is loaded
- `profile.isOnboardingComplete == false`

## Data Collected

The onboarding form edits the same profile draft model later used by profile editing.

### Identity Fields

- `displayName`
- `preferredName`
- `assistantTone`
- `supportStyle`

### Personal Context Fields

- `lifeFocusesText`
- `likesText`
- `dislikesText`
- `boundariesText`

These text fields are converted into string arrays when saved.

### Onboarding Answers

The current prompt set is:

1. What matters most in your life right now?
2. Where are you feeling friction or overwhelm?
3. How should the assistant support you on hard days?
4. What should the assistant avoid doing or saying?
5. What does a good day usually look like for you?

### Summary Field

- `summary`

## Completion Gate

The onboarding completion button is disabled until all of these are true:

- preferred name is non-empty after trimming
- assistant tone is non-empty after trimming
- support style is non-empty after trimming
- at least one onboarding answer is non-empty after trimming

## Save Behavior

When the user finishes onboarding:

- `ProfileStore.saveDraft(markOnboardingComplete: true)` is called
- the draft is converted into `ProfileUpdateRequest`
- the app sends `PATCH /v1/profile`
- `isOnboardingComplete` is set to `true`
- the UI transitions to the ready state

## Seed Behavior

After Apple sign-in, `SessionStore` temporarily stores `pendingDisplayName`.

When the profile loads:

- if the backend profile `displayName` is empty
- `ProfileStore.loadProfile(seedDisplayName:)` seeds `displayName`
- and seeds `preferredName` if `preferredName` was also empty

## Relationship To Memory

The onboarding screen explicitly states that the assistant should use:

- stable profile facts
- remembered preferences
- tone boundaries

It also states that memory use should be based on curated summaries rather than replaying all transcripts.

## What Is Not Specified

The current repo does not define:

- onboarding analytics
- multiple onboarding variants
- localization
- partial-save checkpoints separate from profile save behavior
