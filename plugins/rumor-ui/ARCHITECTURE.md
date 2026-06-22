# rumor-ui v2 — Pixel-Perfect Convergence Engine (design spec)

> Status: **design — not yet built.** This is the build spec for evolving `rumor-ui` from a
> good Figma→code *scaffold* (v0.1) into a closed-loop engine that produces pixel-perfect,
> on-system, human-natural UIs from a single Figma URL and self-corrects until done.
>
> Decisions locked: pixel-diff/device control **depends on Argent MCP**; **iOS simulator
> only**; this doc lands first, implementation follows.

## 1. Goal & operating principle

**One input, solid output:** `/figma-build <figma-url>` → a merged, tested, on-system,
visually-verified screen — no hand-holding between.

The engine rests on four mechanisms, each owning exactly one job. They are sourced from
existing, proven skills (researched 2026-06-22) rather than invented:

| Job | Mechanism | Source |
|---|---|---|
| **Strict input** — only emit tokens/primitives that exist | closed-vocabulary `token-map.json` + `DESIGN.md` + CLAUDE rules + Code Connect | Figma `mcp-server-guide` skills + DESIGN.md spec |
| **Measure** — numeric visual fidelity vs the Figma frame | `argent-screenshot-diff` (Lanczos-normalized pixel + OCR/font diff, changed-region bounds) | software-mansion/argent |
| **Loop** — converge, don't ship-once | `ce-optimize`-shape metric loop, disk-checkpointed, stop on target/plateau/budget | everyinc/compound-engineering-plugin |
| **Gate** — looks-right can't pass alone | `/thermos` + `/code-review` + `/simplify` + standards-reviewer as a residual gate | rumor-plugins (thermos) + bundled skills |

Guiding rule from v0.1 stands: **tighten the loop, then let it rip; verify, don't assert.**
v2 makes "verify" a *number* (mismatch %), not a vibe.

## 2. Dependencies

Hard deps (the plugin orchestrates these; it does not reimplement them):

- **Argent MCP** — `npx @swmansion/argent init`, MCP server running. Used:
  `list-devices` / `boot-device` / `launch-app`, `gesture-*`, `describe` (a11y tree with
  normalized `frame {x,y,w,h}`), `screenshot` (framebuffer, `scale:1.0`,
  `includeImageInContext:false`), `screenshot-diff`, `flow-*` (record/replay nav), and
  `debugger-inspect-element` / `debugger-evaluate` (runtime computed layout).
- **Figma Dev Mode MCP** — `get_design_context`, `get_metadata`, `get_screenshot`,
  `get_variable_defs`, `get_code_connect_map`.
- **XcodeBuild MCP** — build/run the Expo dev client on the sim (Argent drives, XcodeBuild
  builds).
- **thermos plugin** (same marketplace) + bundled `/code-review`, `/simplify` skills.

Soft deps / preconditions: a running Metro + an installed dev client (see
[[rumor-ui-verify-loop]] for the rebuild-after-native-dep-bump gotcha).

## 3. The strict design system layer (the "closed vocabulary")

Strictness = the generator **cannot invent values**. Three generated artifacts enforce it,
produced once per project by a new `/figma-ds-sync` command and refreshed on demand.

### 3.1 `token-map.json` (generated — the keystone)
Maps every Figma variable to its `tailwind.config.js` key and the emitted NativeWind class.
```jsonc
{
  "color/primary":      { "tw": "primary",      "class": "bg-primary / text-primary" },
  "space/4":            { "tw": "4",            "class": "p-4 / gap-4 / m-4" },
  "radius/lg":          { "tw": "lg",           "class": "rounded-lg" },
  "font/heading":       { "tw": "heading",      "class": "font-heading" }
}
```
**Rule:** during generation, every Figma value (`get_variable_defs` for the node) must
resolve to an entry here. **An unmapped value is a hard failure** — the engine stops and
surfaces "Figma uses `#3A7BD5` with no token; add a token or pick the nearest." It never
emits a raw hex/px. This is what turns "should use the design system" into "can only."

### 3.2 `DESIGN.md` (brand layer, human-readable)
The Google-Stitch / designmd 6-section format, but tokens stated as **NativeWind classes**:
Visual Theme & Atmosphere · Color System · Typography · Components & Patterns ·
Spacing & Layout · Motion & Interaction · + Rationale + Accessibility. This is the
"what good looks like" reference the generator and reviewers read.

### 3.3 `code-connect.json` (generated)
`get_code_connect_map` output: Figma component id → `src/components/ui` import + prop/variant
mapping. Component instances resolve to real imports, never re-implemented primitives.

### 3.4 CLAUDE rules block (enforcement prose)
Adapted from Figma's `create-design-system-rules`, NativeWind-flavored, `IMPORTANT:`-prefixed:
> - `IMPORTANT: tokens live in tailwind.config.js — never hardcode hex/px/font names; emit only classes in token-map.json.`
> - `IMPORTANT: primitives live in src/components/ui — reuse them; never recreate one (see code-connect.json).`
> - RN output only: `View/Text/Pressable/Image`, NativeWind `className`, no web CSS.
> - Required Flow (do not skip): parse URL → get_design_context → (get_metadata fallback) →
>   get_variable_defs → resolve via token-map → get_code_connect_map → get_screenshot →
>   download assets → generate → validate.
> - Conflict rule: when a project token conflicts with the Figma spec, **prefer the token and
>   nudge spacing/size minimally** to preserve the visual.

The existing `hooks/check-tsx-standards.sh` already blocks raw hex / arbitrary `[..]` Tailwind
/ `StyleSheet` / `any`; v2 extends it to also flag a class **not present in token-map.json**
(closed-vocabulary enforcement at edit time, not just generation time).

## 4. The convergence loop (`/figma-build`)

Modeled on `ce-optimize` (continuous, metric-gated, disk-checkpointed) — **not** ship-once.
Each fix is its own commit so winners merge and losers revert cleanly.

```
INIT
  parse URL → fileKey, nodeId
  reference  = get_screenshot(node)               # the visual source of truth
  spec       = get_design_context + get_variable_defs (resolved via token-map)
  components = get_code_connect_map
  generate   = on-system NativeWind code (thin route + feature components, per standards)
  record nav = argent flow-record to the screen   # deterministic capture state
  CP-0: write baseline to experiment log (disk)

LOOP (iteration N), each in its own commit:
  1. MEASURE
       build+launch (XcodeBuild) → replay argent flow → argent screenshot
       primary  = argent screenshot-diff(current, reference)  → mismatch% + changed regions
       secondary gates = lint/typecheck, token-map violations, a11y labels present
  2. DIAGNOSE
       cluster changed regions (layout / spacing / color / typography / missing state)
       SEARCH docs/solutions/ui-bugs/ FIRST  → reuse a known fix if the symptom matches
       else rank new fix hypotheses; use argent describe / debugger-inspect-element
            to get exact on-device numbers when a pixel delta is ambiguous
  3. FIX
       apply highest-value fix; fold in /simplify so code stays clean as it converges
  4. RE-VERIFY
       re-measure; improved beyond noise_threshold → commit; else revert, keep best
  5. PERSIST
       append result to experiment log IMMEDIATELY; verify by read-back  (chat ≠ storage)
       update `best`; write a one-line strategy digest (what worked)

RESIDUAL GATE (on convergence candidate)
  /thermos  +  /code-review  +  rumor-ui-standards-reviewer
  done = (mismatch% ≤ TARGET) AND (gate has zero unresolved actionable findings)
                              AND (/simplify produced no further changes)
```

### Stopping criteria — stop when ANY:
- **Target met:** `mismatch% ≤ TARGET` (default ~2%, tunable) **AND** residual gate clean.
- **Plateau:** no improvement beyond `noise_threshold` for `N` consecutive iterations
  (prevents thrashing on sub-pixel anti-aliasing).
- **Budget:** `max_iterations` or `max_wall_clock` hit.
- **Empty backlog:** no untried fix hypotheses remain.
- **Manual stop.**

"Done" is multi-dimensional on purpose: a screen that *looks* perfect but has thermos-critical
findings or off-system classes is **not done**.

### Experiment log (disk, the source of truth)
`.rumor-ui/runs/<run-id>/log.yaml` — append-only: baseline → per-iteration
`{iter, mismatch%, regions, fix, verdict: kept|reverted}` → final. Resumable by scanning
markers (a run can be killed and continued). Never rely on conversation context.

## 5. Pixel-perfect verification via Argent (the measure)

- **Baseline = the Figma frame export** (`get_screenshot`), not an app baseline. Argent's
  Lanczos3 aspect-matched normalization means a Figma export at one resolution diffs cleanly
  against a sim capture at another (downscales the larger; hard-fails on aspect mismatch).
- **Determinism:** record the nav-to-screen sequence once with `argent flow-*`; replay before
  every capture so before/after are byte-identical app state (kills diff noise).
- **Region output:** `screenshot-diff` returns per-region bounds + pixel count + avg color
  delta + dominant channel/direction → DIAGNOSE clusters these into fix hypotheses instead of
  guessing.
- **Text/typography:** the OCR + font-geometry pass flags copy/type drift separately from raw
  pixels (catches a wrong line-height that a color-tolerant pixel pass would miss).
- **Numeric tie-break:** when a pixel delta is ambiguous (sub-pixel, anti-alias), `describe`
  (normalized element frames) + `debugger-inspect-element` (computed layout/style) give exact
  on-device numbers to compare against the Figma token — assert the spacing, don't eyeball it.
- **Status bar:** Argent already masks the top 6% (clock/battery) so it never counts as a diff.

## 6. Imported standards & review rules (raise the floor)

Add to `rumor-mobile-standards` and the `rumor-ui-standards-reviewer` agent (sourced from
Vercel `react-native-skills` + dotneet `typescript-react-reviewer`), the high-value rules we
don't already encode:

- **State = ground truth, not visuals** — store `pressed`/`isOpen`; derive `scale`/`opacity`
  via interpolation. Minimize state; derive during render.
- **Compound components over polymorphic children** — `Button`/`ButtonText`/`ButtonIcon`;
  never accept `string | ReactNode`. (Directly shapes Figma→component generation.)
- **Design-system folder re-export indirection** — app code imports primitives only through
  `src/components/ui`, never directly from RN/3rd-party packages.
- **List rules** — `getItemType` for heterogeneous lists (recycling pools), memoized item +
  stable refs, no inline objects in props.
- **Animation/scroll** — animate only GPU props (transform/opacity); scroll position via
  shared values, never `useState`.
- **Correctness (block-merge tier)** — missing `useEffect` cleanup; no direct mutation;
  `key={index}` ban in dynamic lists; no component-defined-inside-component; the
  `cond && <View>` falsy-`0` bug; text only inside `<Text>`.
- **Review severity tiers** — adopt dotneet's block-merge / high / style tiers + symptom→cause
  table as the structure for the residual gate's review pass.
- **TS strictness** — add `noUncheckedIndexedAccess` (+ `exactOptionalPropertyTypes`);
  TanStack Query is source of truth (never copy server data to `useState`).

## 7. Compounding learnings (gets better every run)

- **`docs/solutions/ui-bugs/`** (`ce-compound` style) — one file per solved symptom, frontmatter
  `{component, token, problem_type, date}`, body = symptom / what-didn't-work / fix / root
  cause / prevention. DIAGNOSE searches this **before** generating new fixes
  (cited effect: repeat fixes 30min → 2min).
- **`CONCEPTS.md` / token glossary** — design-system vocabulary ↔ Figma variables, so every
  run speaks the same language and never re-derives mappings.
- **`CLAUDE.md` routing rule** — "search docs/solutions + CONCEPTS first." This is what turns
  one-off fixes into a compounding asset.
- **`LESSONS.md`** (already exists) — workflow/process deltas via `/ui-retro`.

## 8. Command & file inventory for v2

New/changed commands:
- **`/figma-build <url>`** — the convergence loop (§4). The headline command.
- **`/figma-ds-sync`** — generate/refresh `token-map.json`, `code-connect.json`, `DESIGN.md`,
  and the CLAUDE rules block from `tailwind.config.js` + `src/components/ui` + Figma vars (§3).
- `/figma-screen`, `/figma-audit`, `/ui-verify`, `/ui-retro` — retained; `/figma-audit`
  gains the Argent `screenshot-diff` numeric backend.

New skills:
- **`rumor-ui-convergence-loop`** — the loop control, stopping criteria, experiment-log format.
- **`rumor-ui-pixel-diff`** — how to drive Argent (flow record/replay, baseline=Figma frame,
  region clustering, numeric tie-break).
- **`rumor-strict-design-system`** — the closed-vocabulary model + the three artifacts + the
  conflict rule.

Updated: `rumor-mobile-standards` + `rumor-ui-standards-reviewer` (§6); `check-tsx-standards.sh`
(closed-vocabulary class check).

Generated artifacts (live in `rumor-mobile-expo`, not the plugin): `token-map.json`,
`code-connect.json`, `DESIGN.md`, `docs/solutions/ui-bugs/`, `CONCEPTS.md`, `.rumor-ui/runs/`.

## 9. Build phases (suggested order)

1. **DS layer** — `/figma-ds-sync` + the three artifacts + closed-vocabulary hook check.
   (Highest leverage; makes *any* generation on-system even before the loop exists.)
2. **Measure** — `rumor-ui-pixel-diff` skill wiring Argent (flow + diff + baseline=Figma).
3. **Loop** — `rumor-ui-convergence-loop` + `/figma-build` + experiment log + residual gate.
4. **Raise the floor** — import the §6 standards/review rules.
5. **Compound** — `docs/solutions/ui-bugs/` + `CONCEPTS.md` + search-first routing.

## 10. Open questions / risks

- **Argent + Expo dev-client** interplay: confirm Argent's `launch-app`/`flow` work against an
  Expo *dev client* (deep-link reload), not just a release build. Validate in Phase 2 spike.
- **TARGET threshold** for "pixel-perfect enough": 2% pixel delta is a starting guess; calibrate
  against a few real Rumor screens (fonts/anti-aliasing inflate raw deltas — lean on the
  OCR/font pass + numeric tie-break, not just raw %).
- **Figma frame vs device scale**: ensure the exported frame and sim device match logical size,
  or the aspect-ratio guard hard-fails. May need a fixed reference device (e.g. iPhone 15).
- **Loop cost**: each iteration is a build+launch+diff. Cap `max_iterations` low (e.g. 6) and
  lean on the fix-library to converge in fewer passes over time.
- **Code Connect coverage**: `get_code_connect_map` only helps for components already mapped;
  unmapped Figma components still need the primitive-grep fallback from v0.1.

---

### Sources (researched 2026-06-22)
software-mansion/argent (`screenshot-diff`, `device-interact`, `create-flow`, `metro-debugger`,
`describe`) · figma/mcp-server-guide (`create-design-system-rules`, `implement-design`) ·
designmd.co / Google Stitch DESIGN.md spec · everyinc/compound-engineering-plugin
(`ce-optimize`, `ce-work`, `ce-compound`) · vercel-labs/agent-skills (`react-native-skills`,
`react-best-practices`) · dotneet `typescript-react-reviewer` · wshobson `react-native-architecture`.
