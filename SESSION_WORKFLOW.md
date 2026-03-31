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
