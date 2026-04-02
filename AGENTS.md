# Monorepo Guidance

## Layout

- `apps/ios/NestMind`: iOS app
- `apps/android`: Android app
- `supabase`: shared backend schema, policies, and Edge Functions
- `docs/shared`: canonical product scope, backend contract, architecture, and workspace docs
- `docs/ios`: iOS-only UI docs
- `docs/android`: Android-only UI docs and known drift

## Authoritative Docs

Start with:

- `README.md`
- `docs/INDEX.md`
- `docs/shared/product-definition.md`
- `docs/shared/api-contracts.md`
- `docs/shared/architecture.md`
- `docs/android/known-drift.md`

Use platform READMEs for local setup details:

- `apps/ios/NestMind/README.md`
- `apps/android/README.md`

## Validation Commands

Run from the repo root unless noted otherwise:

```bash
git status --short --untracked-files=all
pwsh -NoProfile -Command "$legacy = @(('..' + '/' + 'my' + '-ai-app'), ('..' + '/' + 'nestmind' + '-android'), ('..' + '/' + '..' + '/' + 'my' + '-ai-app'), ('two' + '-repo'), ('sibling' + ' Android repo')) | ForEach-Object { [regex]::Escape($_) }; rg -n ($legacy -join '|') ."
```

Markdown relative-link check in PowerShell:

```powershell
$files = rg --files -g '*.md' .
foreach ($file in $files) {
  $content = Get-Content -Raw $file
  $matches = [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')
  foreach ($match in $matches) {
    $target = $match.Groups[1].Value
    if ($target -match '^(https?:|mailto:|#)') { continue }
    $cleanTarget = $target.Split('#')[0]
    if ([string]::IsNullOrWhiteSpace($cleanTarget)) { continue }
    if (-not (Test-Path (Join-Path (Split-Path $file -Parent) $cleanTarget))) {
      Write-Output "$file -> $target"
    }
  }
}
```

Platform checks only if tooling is installed:

```bash
cd apps/ios/NestMind && xcodegen generate && xcodebuild -project NestMind.xcodeproj -scheme NestMind -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
gradle -p apps/android :app:assembleDebug
supabase db push
supabase functions deploy api
```

## Do-Not Rules

- Do not re-architect the repo unless fixing a concrete integrity issue.
- Do not invent new product behavior to erase documentation drift.
- Do not silently “fix” Android parity gaps unless the task explicitly requires code changes there.
- Do not bury shared backend or contract docs under a platform folder.
- Do not claim platform validation passed unless the command actually ran in the current environment.

## Drift Expectations

- Preserve working code when docs and code disagree.
- Update shared docs when the shared contract changes.
- Keep Android drift explicit in `docs/android/known-drift.md` until the implementation is actually aligned.
