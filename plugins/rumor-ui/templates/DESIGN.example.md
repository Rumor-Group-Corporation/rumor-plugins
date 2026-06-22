# DESIGN.md — Rumor (example, generated from the real palette)

> Example/reference. `/figma-ds-sync` writes the live `DESIGN.md` to the `rumor-mobile-expo`
> root. Tokens are stated as **NativeWind classes** so generated code copies them directly.
> Every value here must exist in `token-map.json`.

## 1. Visual Theme & Atmosphere
Clean, editorial, near-monochrome. Crisp white canvas, near-black ink, generous whitespace,
soft hairline dividers. Restrained and premium — color is an accent, not a field. Brand
energy comes from one electric lime (`rumor-lime`) used sparingly against the black/white base.
Tags: minimal · editorial · high-contrast · warm-neutral accents.

## 2. Color System
- **Canvas / ink:** `bg-background` (#fff) · `text-foreground` (#1f1f1f).
- **Primary (actions, emphasis):** `bg-primary` / `text-primary` (#1f1f1f), on-primary
  `text-primary-foreground` (#fff).
- **Secondary / muted surfaces:** `bg-secondary` (#eee) · `bg-muted` (#f7f7f7) with
  `text-muted-foreground` (#a2a1a1).
- **Accent (warm):** `bg-accent` (#f3eeea) · `text-accent-foreground` (#a28b7f).
- **Brand:** `bg-rumor-lime` (#b7ff00) — accent only, never large fields or text-on-white.
- **Status:** success `text-success` (#167e60) on `bg-success-bg`; warning `text-warning`
  (#d9a21f) on `bg-warning-bg`; danger/destructive `text-destructive` (#9d0d11);
  info `text-info` (#0d729d).
- **Lines:** `border-border` (#e1e1e1), softer `border-divider-soft` (#e5e5e5).
- **Neutral content scale:** `text-content-neutral` (#b5b5b5) … `text-content-neutral-body`
  (#838282) for secondary text.

## 3. Typography
- **Sans (UI/body):** ABCDiatype — `font-dia-light` / `font-dia` / `font-dia-medium` /
  `font-dia-bold`.
- **Serif (display/editorial):** RomieTrial — `font-romie` / `font-romie-medium` /
  `font-romie-bold`. Use for large display titles and editorial moments, not body.
- **Scale:** `text-stat-display` (40px) · `text-28` (28px) · `text-title` (26px) · base ·
  `text-13` · `text-11` · `text-xxs` (8px).
- **Display titles:** pair large sizes with tight tracking — `tracking-tight-s` (-0.5px) /
  `tracking-tight-m` (-0.75px) — and `leading-snug-x` (1.2). Body uses `leading-relaxed-x` (1.4).

## 4. Components & Patterns
- Build from `src/components/ui/*` primitives (Button, Input, Text, Badge, Sheet, Dialog,
  SegmentedControl, Switch, etc.). Never re-implement one — see `code-connect.json`.
- **Compound components** over polymorphic children (`Button` + `ButtonText`/`ButtonIcon`),
  not a `string | ReactNode` child.
- Bottom-sheet surfaces use the `Dialog`/`bottom-sheet` primitives, not a new sheet dep.
- Pressables over TouchableOpacity; `expo-image` for images.

## 5. Spacing & Layout
- Use the spacing scale via padding/`gap` classes (`p-3`=12, `gap-4`, `p-4.5`=18, `p-5.5`=22,
  `p-7.5`=30…). **`gap` for space-between, padding for space-within** — not child margins.
- Radii: cards/sheets `rounded-2.5xl` (20) / `rounded-3xl` (24) / `rounded-5xl` (32); pills
  `rounded-rumor-full`. Always pair `borderRadius` with `borderCurve: 'continuous'`.
- Respect safe areas; hairline borders at `border` width or `1.5`.

## 6. Motion & Interaction
- Reanimated, native-thread, 60fps. Animate **only GPU props** (transform/opacity); derive
  visuals from ground-truth state via interpolation — never store `scale`/`opacity` in state.
- Scroll position via shared values, never `useState`. Press feedback via Gesture/Pressable,
  not JS state churn.

## Rationale
Near-monochrome + one electric accent reads premium and keeps focus on content. The dual
type system (Diatype sans + Romie serif) gives editorial contrast without a third family.

## Accessibility
- Every interactive element has an `accessibilityRole` + `accessibilityLabel` (also what
  behavior tests query by).
- Maintain contrast: body text at `text-foreground`/`text-content-neutral-body`, never the
  faint `content-neutral` grays for primary copy.
- Hit targets ≥ 44pt; honor reduced-motion for the animation layer.
