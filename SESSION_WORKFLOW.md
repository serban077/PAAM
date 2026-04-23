# Session Workflow — SmartFitAI

## KICKOFF PROMPT

```
SmartFitAI — Flutter + Supabase + Gemini. Single branch: main.

Read in order:
1. CLAUDE.md (root)
2. TASKS.md — find "Next session starts with"
3. Subdirectory CLAUDE.md for today's layer:
   - Screens/UI/nav → lib/presentation/CLAUDE.md
   - Services/Supabase/Gemini → lib/services/CLAUDE.md
   - Data models/exercise DB → lib/data/CLAUDE.md

Run git status. Report: uncommitted changes · milestone+task · files read · first action.
No code until I confirm.
```

---

## END OF SESSION PROMPT

```
End of session. No new features. Complete steps 1–5 in order.
```

### STEP 1 — Commit

One commit per feature/fix. Format:
```
<type>(scope): short description

- bullet detail 1
- bullet detail 2
```
Types: `feat` / `fix` / `refactor` / `docs` / `chore` / `perf`

**NEVER add Co-Authored-By. Author: serban077 <serban.07@yahoo.com> only.**

Examples:
```
feat(auth): complete onboarding survey with fitness profile collection
- Multi-step form: goals, fitness level, dietary preferences, physical stats
- Saves response to onboarding_responses Supabase table
- On completion, redirects to /main-dashboard
```
```
feat(ai-workout): integrate Gemini plan generation into AIWorkoutGenerator screen
- GeminiAIService.generatePersonalizedPlan() wired to Generate button
- Loading skeleton shown during generation
- AIPlanResponse parsed and displayed as WorkoutPlanCard widgets
```
```
fix(bottom-nav): replace Romanian labels with English
- "Acasă" → "Home", "Antrenamente" → "Workouts", "Nutriție" → "Nutrition"
```
```
docs(session): update CLAUDE.md, TASKS.md after M9 UI polish
- Marked M9 tasks [x] in TASKS.md
- Updated Current Status block with next session target
```

After all commits:
```bash
git log --oneline -8
git push origin main
```

---

### STEP 2 — Update TASKS.md

- Mark completed: `- [x]`
- Mark partial: `> ⚠️ Partially done: [what was done / what remains]`
- Add new tasks as `- [ ]` under the correct milestone
- Update status block:

```markdown
## Current Status
**Last updated:** [DATE]
**Last session completed:** [M number + brief description]
**Next session starts with:** [exact task text]
**Active branches:** main
**Blockers / notes:** [anything for next session]
```

---

### STEP 3 — Update root CLAUDE.md

Update only `## Current Status`:
```markdown
## Current Status
**Last updated:** [DATE]
**Last session:** [M number + brief description]
**Next session starts with:** [exact task]
**Active branches:** main
**Blockers:** [blockers or "none"]
```
Add new global NEVER/ALWAYS rules only if discovered this session. Keep file under 300 lines.

---

### STEP 4 — Update subdirectory CLAUDE.md files

- `lib/presentation/CLAUDE.md` — add new screen to table, document nav/widget patterns
- `lib/services/CLAUDE.md` — add service to inventory, new Supabase tables, Gemini prompt patterns
- `lib/data/CLAUDE.md` — document new model fields, exercise DB changes

Keep every file under 300 lines.

---

---

## RELEASE BUILD COMMANDS (added M31)

### Standard release APK (single universal APK)
```bash
flutter build apk --release --dart-define-from-file=env.json
```

### Per-ABI APKs (recommended for Play Store — ~40% smaller download per device)
```bash
flutter build apk --release --split-per-abi \
  --split-debug-info=build/symbols \
  --obfuscate \
  --dart-define-from-file=env.json
```
Outputs: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (most modern devices), `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`.

### App Bundle (Google Play — preferred over APK)
```bash
flutter build appbundle --release \
  --split-debug-info=build/symbols \
  --obfuscate \
  --dart-define-from-file=env.json
```

### APK size analysis
```bash
flutter build apk --release --analyze-size --dart-define-from-file=env.json
```

> **Debug symbols:** `build/symbols/` holds de-obfuscation info for Sentry. **Never commit this directory** (gitignored). Upload to Sentry via `sentry-cli debug-files upload build/symbols/` after each release.

---

## TEST & CI REFERENCE (added M30)

### One-time developer setup (run after cloning)
```bash
bash scripts/setup-hooks.sh   # installs pre-commit hook at .git/hooks/pre-commit
```

### Pre-commit hook behavior
- Runs `flutter analyze lib/ --no-fatal-infos`
- Runs `dart format --set-exit-if-changed lib/`
- Blocks commit if either fails. Fix: `dart format lib/` then re-stage.

### Running tests locally
```bash
flutter pub get
flutter test test/unit/              # pure logic — always run before committing
flutter test test/widget/            # UI tests (needs no device)
flutter test test/unit/ test/widget/ --coverage   # with lcov report
# DO NOT run --update-goldens locally (platform mismatch)
```

### Golden file workflow
- Goldens are generated on `ubuntu-latest` in CI only.
- To update goldens: push a commit → go to GitHub → Actions → "Update Goldens" → Run workflow.
- The action commits new PNGs back to the branch automatically.
- Locally, `flutter test test/golden/` will FAIL if no PNG files exist — that is expected on Windows.

### CI pipeline (GitHub Actions)
- Triggers: push + PR to `main`
- Jobs: `flutter pub get` → `flutter analyze lib/` → unit tests → widget tests → golden tests (continue-on-error) → coverage upload
- Golden test failures do NOT block CI (pending first-run generation via `update-goldens` workflow).

### Coverage
- Report generated at `coverage/lcov.info` (gitignored, generated on demand).
- Targets: services ≥ 40%, overall ≥ 25%.

---

### STEP 5 — Session summary

```
## Session Summary — [DATE]

### Completed:
- [Mx] Task — done

### Partial:
- [Mx] Task — [done / remaining]

### Not started:
- [Mx] Task

### Next session starts with:
[Exact task from TASKS.md]

### Files modified:
- lib/...

### Commits pushed:
- [hash] type(scope): description

### Notes for next session:
[Context, decisions, gotchas]
```
