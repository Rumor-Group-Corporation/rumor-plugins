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

## Definition of done

```bash
yarn lint && yarn typecheck && yarn format:check && yarn build
```
No errors, no warnings. `yarn build` must succeed before declaring work complete.

## Before creating anything

Scan first. If a component/hook/store/type/constant/utility already exists, reuse or
extend it. Flag and consolidate duplication when you spot it.
