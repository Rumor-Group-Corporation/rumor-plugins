---
name: rumor-behavior-testing
description: The Rumor mobile test harness - behavior-driven RNTL/jest testing plus every react-native/jest gotcha we've already hit and solved. Use when writing or fixing tests for rumor-mobile-expo components, hooks, or screens, or when a jest test mysteriously throws on reanimated, NativeWind, expo, or TanStack Query.
---

# Rumor Behavior Testing

Philosophy (Kent C. Dodds / Testing Library): **test the way the software is used, mock
only at the system boundary, assert observable behavior.** If an assertion reaches into
`useState` or a `testID` on an internal node, you're testing implementation. If it presses
a labeled control and checks what the user would see, you're testing behavior.

## The testing trophy (what to test at each layer)

- **Pure functions** (utils/schema): input -> output, no React.
- **Hooks** (`renderHook` + a QueryClient wrapper): optimistic update + rollback, gating,
  retry. Mock the service layer + stores.
- **Components** (`render`/`fireEvent`): query by **role / a11y label / visible text**;
  assert outcomes (a toast fired, a row disabled, `onOpenChange(false)` called). Never
  internal state.
- **Integration** (mount the screen): the empty / permission / loading / error matrix, tab
  switching, search.

Always cover the **state matrix**, not just the happy path.

## RN/Jest gotchas (so you don't rediscover them)

- **react-native-reanimated 4 + worklets 0.8 can't init under jest** — the shipped `/mock`
  throws. Use a manual mock returning plain RN hosts + **chainable no-op animation
  builders**: `SlideInDown.duration().springify().damping()...` must all return the
  builder. Add **every** chained method the code uses (incl. `damping`, `mass`,
  `LinearTransition`) or it explodes.
- **NativeWind's babel transform rewrites `React.createElement`** inside `jest.mock`
  factories -> "out-of-scope variable" errors. Mock native components as `() => null` or
  `({ children }) => children` — **no JSX / no `createElement`** in the factory.
- **`jest.mock` factory variables must be `mock`-prefixed** (`mockFoo`) or jest rejects the
  out-of-scope reference.
- **The shared `BottomSheet` can't mount under jest** — `@/components/ui/bottom-sheet`
  imports `scheduleOnRN` from `react-native-worklets` (native part uninitialized) and renders
  a `GestureDetector` (needs `Reanimated.useEvent`) on `.set()/.get()` shared values. Don't
  whack-a-mole the global reanimated/worklets mocks; **mock the module in the test**:
  `jest.mock('@/components/ui/bottom-sheet', () => ({ BottomSheet: ({ open, children }) => open ? children : null }))`.
  Return `children` directly — **no `createElement`** (NativeWind rewrites it → out-of-scope
  error). Type the params with an inline `import('react').ReactNode` (erased, so it won't trip
  the hoist rule) to satisfy `noImplicitAny`. Text-based assertions then pass unchanged. (No
  BottomSheet-based drawer is unit-tested otherwise — find-contacts/recipients have no tests.)
- **Babel's jest-hoist reads identifiers inside type annotations** in a mock factory — an
  `as (prev: T) => T` cast flags `prev` as "out-of-scope". Keep factory types simple (drop the
  cast / use `unknown`), since the factory only needs runtime behavior, not precise types.
- **Don't replace the whole `expo` module** — `expo-image` needs `requireNativeModule`.
  Spread `...(jest.requireActual('expo') as object)` and override just what you need
  (e.g. `useEvent`).
- **TanStack Query test client:** `gcTime: Infinity` (not 0), or `setQueryData` is GC'd
  before you can assert it with no observer mounted.
- **`@/lib/env` throws at import** (missing Expo config) -> global-mock it in `jest.setup`
  so any component can mount.
- **`jest.clearAllMocks()` returns the Jest object** -> in `beforeEach(() => ...)` arrow
  form it trips the "test returns a value" TS rule; use a **block body**:
  `beforeEach(() => { jest.clearAllMocks(); })`.
- **`In([...])` FindOperator assertions** (when a test reaches a TypeORM-shaped mock):
  assert against `criteria.field.value` (the operator's `.value`), not the operator object.

## Backend tests (scheduler/services, ts-jest)

The backend uses jest + ts-jest with `roots` scoped per package. To test a new service,
**extend `roots`** to its `src`, mock the two boundaries (the TypeORM query-builder chain +
the service-mesh call), and assert behavior: one notification per recipient, input
sanitisation, per-recipient error isolation, clear-only-on-success, bulk delete (no N+1),
and the query shape (incl. explicit `WHERE`/`HAVING` invariants).

Run with `npm test` (the repo's local jest) — **not** `npx jest`, which fetches a stray
jest without ts-jest. `node_modules/rumor-utils` is a symlink to `packages/rumor-utils` so
bare `rumor-utils/...` specifiers resolve.

## Mock at boundaries — the standard set

video player, reanimated, expo `useEvent`, the service layer, Zustand stores, and
`@/lib/env`. Everything else renders for real so the test exercises real behavior.
