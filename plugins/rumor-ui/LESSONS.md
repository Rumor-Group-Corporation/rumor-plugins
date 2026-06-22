# rumor-ui — Lessons Ledger

The consistently-improve loop. Every screen we ship should leave this plugin smarter than
it was. When something breaks, is manual, or surprises us, `/ui-retro` folds the rule into
the right skill — and the not-yet-categorized one-offs (Figma-node mappings, project quirks)
land here with a date and one-line context.

This file is reviewed like code. Keep entries tight: **symptom -> rule -> where it lives now.**

## Format

```
### YYYY-MM-DD — short title
Symptom: what we observed.
Rule: the durable takeaway.
Home: which skill/hook it was added to (or "ledger only").
```

---

## Ledger

### 2026-06-22 — plugin seeded from the Rumor Mutuals build
Symptom: the entire Figma->code workflow lived in one engineer's head + a markdown doc.
Rule: codify it as skills/commands/hook/agents so every engineer (and the agent) inherits
the accumulated edge cases — reanimated-4 mock, NativeWind babel factory rewrite, dev-client
rebuild after native dep bumps, the staging-table seam, the no-N+1 digest, behavior-only
tests, the pixel-tight sim loop.
Home: seeded across `figma-to-screen`, `rumor-mobile-standards`, `rumor-behavior-testing`,
`rumor-ui-verify-loop`, and the standards hook.

<!-- Append new lessons above this line. Newest first. -->
