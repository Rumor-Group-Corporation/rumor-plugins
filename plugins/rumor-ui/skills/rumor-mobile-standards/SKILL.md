---
name: rumor-mobile-standards
description: How we write UI code in rumor-mobile-expo - the enforced coding standards. Use when writing or reviewing any component, screen, hook, store, or styling in the Expo mobile app, or when deciding where a file belongs. Distilled from the repo's AGENTS.md / CLAUDE.md so the rules travel with the agent.
---

# Rumor Mobile Standards

The canonical source is `AGENTS.md` / `CLAUDE.md` in `rumor-mobile-expo` — read it when in
doubt. This skill is the working distillation plus the rationale, so the agent writes
code that passes review and the standards hook on the first try.

**Stack:** Expo SDK 56 + Expo Router · React Native · NativeWind · `src/components/ui/`
primitives · TanStack Query (server state) · Zustand (client state) · react-hook-form + zod.

> Expo changed. Before using an unfamiliar Expo API or touching native config, check the
> **versioned SDK 56 docs** (use context7) — don't trust older assumptions.

## Where code goes (file placement is a rule, not a preference)

- **Routes** (`src/app/`) stay thin: params, query/mutation wiring, state, navigation
  orchestration. No bulky `renderItem` JSX.
- **Feature UI** -> `src/components/<feature>/` (e.g. `auth/`, `guests/`, `events/`,
  `rumor-mutuals/`). Never leave feature components flat at `src/components/`. Reserve the
  root for genuinely cross-feature building blocks.
- **Primitives** -> `src/components/ui/`. Compose from them; don't fork them for one-offs —
  extend via props, variants, `className`.
- **Helpers/domain logic** -> `src/lib/<feature>/` (display, parsing, normalization,
  calculation). Never inside routes/components.
- **API** -> thin services layer under `src/lib/<feature>/` or `src/services/`, exposed via
  TanStack Query hooks under `src/hooks/api/<feature>/`. Components never call `fetch`/`axios`.
- **Schemas** -> `_schema.ts`; derive types with `z.infer`.
- **Routes constants** -> `src/lib/routes.ts`; feature route helpers in
  `src/lib/<feature>/routes.ts`.

## Styling (NativeWind only)

- `className` utilities are the styling language. **No** `twrnc`, `StyleSheet.create`,
  component stylesheets, CSS modules, or custom CSS for UI.
- **No static inline `style`** for layout/spacing/size/color/typography/borders. Inline
  `style` is allowed *only* for runtime-calculated values and native APIs with no
  `className` path — animated transforms, dynamic safe-area offsets, React Navigation
  screen options, measured positioning.
- **No arbitrary `[..]` values.** Use the Tailwind scale or add a reusable token to
  `tailwind.config.js`. Keep brand/semantic colors, fonts, spacing, radii there.
- Tailwind theme keys must be **generic/reusable** (scale or semantic names), never named
  after one component. Don't add color constants to `src/constants/theme.ts`; resolve raw
  native colors from `tailwind.config.js`.
- Register custom fonts in `src/lib/fonts.ts`, mirror in `tailwind.config.js`, list the
  file in the `expo-font` plugin in `app.json`.
- Light-mode first. No dark-mode complexity unless the product decision is explicit.
- Use `cn()` from `src/lib/utils.ts` for conditional classes.

## TypeScript

- Prefer arrow functions; props use `FC<Props>` unless generics are needed.
- **No `any`** (blocked by ESLint), **no non-null `!`**, **no `@ts-ignore`/`@ts-nocheck`**
  (`@ts-expect-error` only with a short reason and no safer option).
- Narrow `unknown` at boundaries. Prove values exist with control flow/guards.
- Treat **react-hooks dependency warnings as build-breaking** — fix the deps or restructure.
  The repo's **react-compiler lint** forbids reading a ref or calling `setState` in
  render/effects; this forces genuinely clean designs — don't paper over it.
- Remove unused imports/vars/exports; no debug `console` output.

## State & data

- Server cache lives in TanStack Query; don't duplicate it in Zustand.
- Zustand stores are small, one-concern, in-memory by default; co-locate selectors, select
  narrow slices. **No auth tokens** in Zustand or plain storage (Secure Store when auth lands).
- Query keys stable, scoped, colocated with the hook.

## Forms

- react-hook-form + zod + `zodResolver`. One `z.object` schema per form. No inline
  validation in components. Map server errors with `setError`.

## Navigation gotcha

The floating bottom tab bar (`src/components/app-tabs.tsx`) draws over every screen in a
tab's stack. Full-screen pushed routes must hide it: add the route name to
`FULLSCREEN_NESTED_ROUTES` in `AppTabBar` — don't re-implement the check.

## Overlays & drawers (match the app, don't mix systems)

Two overlay systems exist and they animate differently: `ui/dialog` (`DialogSheetContent`,
a Reanimated layout slide) and `ui/bottom-sheet` (`BottomSheet`, the gesture-driven
`BOTTOM_SHEET_SPRING_CONFIG` — heavily damped, `overshootClamping`, drag-to-dismiss). The
network/announcements drawers use **`BottomSheet`**; a screen that uses `Dialog` for a
"drawer" will look off next to them (fast/bouncy slide vs the app's settle — RUM-7842). Rule:
a bottom-anchored **drawer that should match the app's other drawers uses the shared
`BottomSheet`**; reserve `Dialog` for centered modals / quick confirms. Don't introduce a
third sheet system — both already exist.

## Performance & architecture rules (RN-specific)

Imported from the Vercel `react-native-skills` + dotneet `typescript-react-reviewer` research
(2026-06-22) — the rules most worth enforcing that the base standards above don't already cover.

**Component design**
- **State = ground truth, not visuals.** Store the *cause* (`pressed`, `isOpen`, `index`), never
  the derived visual (`scale`, `opacity`, `translateY`). Derive visuals via interpolation in the
  animation layer. Minimize state; derive during render where you can.
- **Compound components over polymorphic children.** `Button` + `ButtonText`/`ButtonIcon`, not a
  `children: string | ReactNode` prop. Never accept a bare string child unless the component is a
  `*Text` component. (This is also how Figma component variants should map to code.)
- **Design-system re-export indirection.** App code imports primitives only through
  `src/components/ui` — never directly from `react-native` / third-party packages. Wrap once, import
  everywhere from the wrapper.
- **No component defined inside another component** (re-creates the type every render → remounts).

**Lists**
- Virtualize (FlashList/LegendList) — never `.map()` a large array into a ScrollView.
- Memoize the item component; pass **stable** function refs (`useCallback`) and **no inline
  objects** as props.
- `getItemType` for heterogeneous lists (separate recycling pools).
- Never `key={index}` in a dynamic/reorderable list — use a stable id.

**Animation & scroll**
- Animate **only GPU props** (transform/opacity). Use `useDerivedValue`/interpolation.
- Scroll position lives in a **shared value, never `useState`** (state churn = dropped frames).
- Press feedback via `Gesture`/`Pressable`, not JS state toggles.
- Pair every `borderRadius` with `borderCurve: 'continuous'`; use `gap` over child margins.

**Correctness (block-merge)**
- No `cond && <View/>` with a numeric `cond` (renders a stray `0`). Use `cond ? <View/> : null`.
- All text inside `<Text>`.
- `useEffect` that subscribes/sets must clean up. No direct state mutation (`.push`/`arr[i]=`).
- No conditional hooks; complete dependency arrays.

**TypeScript / data**
- TanStack Query is the source of truth for server data — **never copy it into `useState`**.
- Prefer `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes` discipline (narrow indexed
  access; don't pass `undefined` to required optionals).
- Context pattern: null default + a null-checking hook + a memoized provider value.

## Definition of done

The five gates `mobile-ci.yml` runs, in CI order — match them exactly and run locally first:

```bash
yarn lint          # eslint src --max-warnings 0  (one warning fails CI)
yarn typecheck     # tsc --noEmit
yarn format:check  # prettier --check .
yarn test --ci     # jest --ci --forceExit
yarn build         # the repo's build verification
```
No errors, **no warnings** (`--max-warnings 0`). All five must pass before declaring work
complete — and again after any merge, even a no-conflict one (see [[rumor-ui-verify-loop]]).

## Before creating anything

Scan first. If a component/hook/store/type/constant/utility already exists, reuse or
extend it. Flag and consolidate duplication when you spot it.
