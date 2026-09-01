# Rumor review stack — the reviewers you can actually dispatch

`rce-review` does not invent a review harness. It routes to the reviewers Rumor
already runs, dispatched as independent contexts so their agreement is real
corroboration (two separately-dispatched contexts, not two lenses in one head).

## Reviewers available in this environment

| Reviewer | How to invoke | Best for |
|----------|----------------|----------|
| **opus-reviewer** (agent) | `Agent` tool, `subagent_type: "opus-reviewer"` | Adversarial correctness/security gate on a diff, on Opus 4.8, against the rumor-platform **8-class defect checklist**. Returns BLOCK/PASS. The default gate for fleet-generated or high-risk slices. |
| **thermos — branch audit** | `Agent`, `subagent_type: "thermos:thermo-nuclear-review-subagent"` | Deep bugs / breaking changes / security / feature-flag leaks, scoped to the diff. Parent gathers diff + file contents first. |
| **thermos — code quality** | `Agent`, `subagent_type: "thermos:thermo-nuclear-code-quality-review-subagent"` | Maintainability, structure, 1k-line rule, spaghetti. |
| **code-simplifier** (agent) | `Agent`, `subagent_type: "code-simplifier:code-simplifier"` | Reuse / simplification / dead-code pass. |
| **/code-review** (built-in skill) | `Skill` tool, `code-review` | Multi-persona correctness + cleanup at a chosen effort; `--comment` posts inline PR comments, `--fix` applies. |
| **/security-review** (built-in) | `Skill` tool, `security-review` | Focused security pass. |
| **rams** (MCP) | `mcp__rams__quick_review` / `review_files` | UI-code design/accessibility review (React/Vue/SwiftUI/CSS). Use on `web-2.0` / `rumor-mobile-expo` UI diffs. |
| **rumor-ui standards** (agent) | `Agent`, `subagent_type: "rumor-ui:rumor-ui-standards-reviewer"` | `rumor-mobile-expo` file-placement / NativeWind / token standards. |

## The bots run in CI, not here

**OpenCodeReview (OCR)** and **Cursor Bugbot** review the PR after it opens — they
are CI reviewers, not local tools. You never invoke them; you **respond** to them
(LAW 4) in `rce-babysit`. OCR is metered (~$4.67/PR measured, one PR hit $90.80/day)
— do not trigger extra runs by force-pushing needlessly.

## The 8-class defect checklist (rumor-platform)

opus-reviewer keys off these. Use the same classes when you self-select personas
for any repo:

1. Correctness / logic
2. Security / authz (host-added vs guest edges, token scope, RLS)
3. Data integrity / migrations (TypeORM `UPDATE...RETURNING` returns
   `[rows, rowCount]`; enum drift; default-false columns hiding rows)
4. Error handling / failure modes
5. Concurrency / ordering (advisory-lock leaks on the Neon pooler)
6. Performance / N+1 / query cost
7. Test coverage of the change
8. Feature-flag leaks (a preview has **no PostHog token** — flags fall back;
   a flag gating a code path must not ship half-wired)

## How rce-review chooses (risk-driven)

- **Any diff:** `/code-review` at an effort matched to risk, **plus** one
  independent adversarial context (opus-reviewer for correctness/security-heavy
  diffs; thermos branch-audit for large/structural ones).
- **UI diff** (`web-2.0`, `rumor-mobile-expo`): add `rams` and, on expo, the
  rumor-ui standards reviewer.
- **Migration / auth / payments touched:** opus-reviewer is mandatory, not
  optional; default its verdict to BLOCK when a blocker-class defect cannot be
  ruled out.

Dispatch the chosen reviewers as **one concurrent batch**, collect all verdicts,
then reconcile: a finding two independently-dispatched reviewers raise is promoted;
a lone high-confidence blocker still blocks. Record what you dispatched and what
each returned — faithfully (LAW 10).
