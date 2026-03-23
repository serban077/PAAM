# Session Workflow — SmartFitAI

Kickoff and end-of-session prompts for Claude Code sessions.

---

## KICKOFF PROMPT (paste at the start of every session)

```
We are working on SmartFitAI — a Flutter mobile app for AI-powered fitness and nutrition planning.
Stack: Flutter + Supabase + Google Gemini. Single branch: main.

Read the following files in order before doing anything:
1. `CLAUDE.md` (root) — rules, commands, route map, current status
2. `TASKS.md` — find the exact task listed under "Next session starts with"
3. The subdirectory CLAUDE.md for the layer we will work on today:
   - Screens / UI / navigation → `lib/presentation/CLAUDE.md`
   - Services / Supabase / Gemini / auth → `lib/services/CLAUDE.md`
   - Data models / exercise database → `lib/data/CLAUDE.md`
   - If the session spans multiple layers, read all relevant ones.

After reading, run `git status` and tell me:
- Any uncommitted changes from the previous session
- Which milestone and task we are starting from (from TASKS.md)
- Which CLAUDE.md files you read
- What you plan to do first

Do NOT write any code until I confirm the plan.

During the session:
- Follow all NEVER / ALWAYS rules from root CLAUDE.md
- One commit per completed feature — never bundle unrelated changes
- If a new pattern or important convention emerges, update the relevant subdirectory CLAUDE.md
- Keep every CLAUDE.md file under 300 lines
- Do not start a new milestone until the current one is fully complete
- Do not redo work that is already marked [x] in TASKS.md
```

---

## END OF SESSION PROMPT (paste when done or context is getting low)

```
We are at the end of this working session.
Complete the following steps in order. Do NOT skip any step. Do NOT start new feature work.
```

---

### STEP 1 — Git: Commit all completed work

Create one separate commit per feature or fix completed this session.
Never bundle unrelated changes into one commit.

Commit format:
```
<type>(scope): short description

- bullet detail 1
- bullet detail 2
- bullet detail 3
```

Types: `feat` / `fix` / `refactor` / `docs` / `chore` / `perf`

IMPORTANT: NEVER add Co-Authored-By or any Claude attribution.
All commits are authored by serban077 <serban.07@yahoo.com> only.

**Examples:**

```
feat(auth): complete onboarding survey with fitness profile collection

- Multi-step form: goals, fitness level, dietary preferences, physical stats
- Saves response to onboarding_responses Supabase table
- On completion, redirects to /main-dashboard
```

```
feat(ai-workout): integrate Gemini plan generation into AIWorkoutGenerator screen

- GeminiAIService.generatePersonalizedPlan() wired to Generate button
- Loading skeleton shown during generation (replaces spinner)
- AIPlanResponse parsed and displayed as WorkoutPlanCard widgets
```

```
fix(bottom-nav): replace Romanian labels with English

- "Acasă" → "Home", "Antrenamente" → "Workouts"
- "Nutriție" → "Nutrition", "Progres" → "Progress", "Profil" → "Profile"
```

```
feat(progress): add body measurements tracking (M7)

- BodyMeasurementsService: save/load from body_measurements Supabase table
- MeasurementsTrackingWidget: input form for chest, waist, hips, arms
- Connected to ProgressTrackingScreen measurements tab
```

```
docs(session): update CLAUDE.md, TASKS.md after M9 UI polish

- Marked M9 localization tasks [x] in TASKS.md
- Updated Current Status block with next session target
- Added Romanian string locations to lib/presentation/CLAUDE.md gotchas
```

After all commits, run:
```bash
git log --oneline -8
git push origin main
```

---

### STEP 2 — Update TASKS.md

- Mark every completed task `- [x]`
- Annotate partial work: `> ⚠️ Partially done: [what was done / what remains]`
- Add any newly discovered tasks as `- [ ]` under the correct milestone
- Update the status block at the top of `TASKS.md`:

```markdown
## Current Status

**Last updated:** [DATE]
**Last session completed:** [M number + brief description]
**Next session starts with:** [exact task text from TASKS.md]
**Active branches:** main
**Blockers / notes:** [anything that needs attention next session]
```

---

### STEP 3 — Update root CLAUDE.md

Update only the `## Current Status` section:

```markdown
## Current Status

**Last updated:** [DATE]
**Last session:** [M number + brief description]
**Next session starts with:** [exact task from TASKS.md]
**Active branches:** main
**Blockers:** [anything blocking progress, or "none"]
```

If a new global rule was discovered this session (a NEVER or ALWAYS that applies everywhere),
add it to the relevant section. Keep the file under 300 lines.

---

### STEP 4 — Update subdirectory CLAUDE.md files

For each layer worked on this session, update the relevant file:

**`lib/presentation/CLAUDE.md`** — if you added/changed screens:
- Add the new screen to the Implemented Screens table
- Document any new navigation pattern or widget reuse rule

**`lib/services/CLAUDE.md`** — if you added/changed a service:
- Add the service to the Service Inventory table
- Document any new Supabase table accessed
- Document any new Gemini prompt pattern

**`lib/data/CLAUDE.md`** — if you added/changed a model:
- Document the new model's field structure
- Update the exercise database notes if the data shape changed

Keep every subdirectory CLAUDE.md under 300 lines.

---

### STEP 5 — Final session summary

```
## Session Summary — [DATE]

### Completed this session:
- [M number] Task description — done

### Partially completed:
- [M number] Task description — [what was done / what remains]

### Not started:
- [M number] Task description

### Next session starts with:
[Exact task text from TASKS.md]

### Files created / modified:
- lib/...
- lib/...

### Commits pushed:
- [hash] type(scope): description
- [hash] type(scope): description

### Notes for next session:
[Any context, decisions, or gotchas Claude should know]
```

---

## QUICK REFERENCE — Common Commands

```bash
# Start session
flutter pub get
flutter run --dart-define-from-file=env.json

# During development
flutter analyze                          # Lint check
flutter run --dart-define-from-file=env.json --hot-reload

# Build
flutter build apk --release             # Android
flutter build ios --release             # iOS

# Git
git status
git add lib/path/to/file.dart
git commit -m "feat(scope): description"
git push origin main
git log --oneline -8
```

---

## SUBDIRECTORY CLAUDE.md — What Each File Contains

| File | Read when... | Contains |
|---|---|---|
| `CLAUDE.md` (root) | Every session | Commands, tech stack, NEVER/ALWAYS rules, route map, env vars, current status |
| `lib/presentation/CLAUDE.md` | Working on screens or UI | Screen template, navigation, auth flow, bottom nav, design tokens, Sizer sizing, screen inventory |
| `lib/services/CLAUDE.md` | Working on Supabase, Gemini, or service logic | Service pattern, Supabase table reference, GeminiAIService API, AuthService methods, all service inventory |
| `lib/data/CLAUDE.md` | Working on data models or exercise data | AIPlanResponse hierarchy, exercise map structure, model conventions |

**Rule:** When in doubt, read all three — they are short by design.
