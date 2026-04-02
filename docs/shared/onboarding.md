# Onboarding

## Purpose

The current onboarding flow teaches NestMind how to help a specific signed-in user before the main app becomes available.

This document describes the canonical onboarding contract. Android deviations are tracked in [../android/known-drift.md](../android/known-drift.md).

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

- `lifeFocuses`
- `likes`
- `dislikes`
- `boundaries`

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

Canonical onboarding completion requires all of these to be true:

- preferred name is non-empty after trimming
- assistant tone is non-empty after trimming
- support style is non-empty after trimming
- at least one onboarding answer is non-empty after trimming

## Save Behavior

When the user finishes onboarding:

- the client sends `PATCH /v1/profile`
- `isOnboardingComplete` is set to `true`
- the app should not advance until save succeeds

The iOS implementation already follows that contract. Android currently advances too early.

## Relationship To Memory

The onboarding flow is explicitly about collecting:

- stable profile facts
- remembered preferences
- tone boundaries

It is not a substitute for conversation-derived memory extraction.
