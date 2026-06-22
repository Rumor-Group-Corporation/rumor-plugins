---
description: Capture a new learning from this session and fold it into the rumor-ui plugin so it improves over time.
argument-hint: "[short description of what was learned]"
---

# /ui-retro — feed the learning back

The plugin is only as good as the lessons fed into it. Capture what just happened: **$ARGUMENTS**

## Steps

1. **Name the delta.** What broke, was manual, or surprised us this session? State it as a
   concrete rule, not a vague observation. (e.g. "reanimated needs `.mass()` in the
   chainable mock", "Figma `Card/elevated` maps to `ui/card` with `shadow-md` token", "the
   tab bar overlaps pushed `events/[eventId]/guests` — add to `FULLSCREEN_NESTED_ROUTES`").
2. **Route it to the right home:**
   - A coding/placement/styling rule -> `skills/rumor-mobile-standards/SKILL.md`.
   - A jest/RNTL gotcha -> `skills/rumor-behavior-testing/SKILL.md`.
   - A sim/native/runtime gotcha -> `skills/rumor-ui-verify-loop/SKILL.md`.
   - A workflow/process change -> `skills/figma-to-screen/SKILL.md`.
   - A **solved Figma↔code visual delta** (spacing/color/typography/layout mismatch you fixed)
     -> a new entry in `rumor-mobile-expo`'s `docs/solutions/ui-bugs/` per
     [[rumor-ui-fix-library]] (so DIAGNOSE finds it next run). A new token mapping ->
     `CONCEPTS.md`.
   - A Figma-node -> primitive/token mapping, or anything not yet fitting above ->
     `LESSONS.md` (the ledger), with a date and one-line context.
3. **Edit the file** — append the rule in the existing voice/format. Keep it tight and
   high-signal; one rule, the symptom, the fix.
4. **Add a standards-hook check if it's enforceable.** If the lesson is a hard rule a regex
   can catch (a banned API, a placement mistake), add it to
   `hooks/check-tsx-standards.sh` so it's enforced automatically next time, not just
   documented.
5. **Bump the plugin version** in `.claude-plugin/plugin.json` (patch) and note the change
   in `LESSONS.md`. Commit on a branch and open a PR against `rumor-plugins` —
   the plugin is reviewed like code.

This is the consistently-improve loop: every screen shipped makes the next one easier.
