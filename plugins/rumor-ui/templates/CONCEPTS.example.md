# CONCEPTS.md — Rumor design vocabulary (example)

> The human-readable glossary mapping **Figma variable ↔ NativeWind class ↔ value**, so every
> Figma->code run speaks one language. Companion to the machine-readable `token-map.json`.
> `/figma-ds-sync` keeps this in sync; generated from the real `tailwind.config.js`.

## Colors
| Figma variable | NativeWind | Value | Use |
|---|---|---|---|
| Color/Background | `bg-background` | #ffffff | app canvas |
| Color/Foreground | `text-foreground` | #1f1f1f | primary ink |
| Color/Primary | `bg-primary` / `text-primary` | #1f1f1f | actions, emphasis |
| Color/Primary-On | `text-primary-foreground` | #ffffff | text on primary |
| Color/Muted | `bg-muted` | #f7f7f7 | muted surface |
| Color/Muted-On | `text-muted-foreground` | #a2a1a1 | secondary text |
| Color/Accent | `bg-accent` | #f3eeea | warm accent surface |
| Color/Brand-Lime | `bg-rumor-lime` | #b7ff00 | brand accent (sparingly) |
| Color/Destructive | `text-destructive` | #9d0d11 | errors/destructive |
| Color/Border | `border-border` | #e1e1e1 | hairline dividers |

## Typography
| Figma style | NativeWind | Family |
|---|---|---|
| Body / UI | `font-dia` / `font-dia-medium` / `font-dia-bold` | ABCDiatype (sans) |
| Display / Editorial | `font-romie` / `font-romie-medium` | RomieTrial (serif) |

Display titles pair with `tracking-tight-s` (-0.5px) / `tracking-tight-m` (-0.75px) and
`leading-snug-x` (1.2); body uses `leading-relaxed-x` (1.4).

## Spacing (between = gap, within = padding)
| Figma | NativeWind | px |
|---|---|---|
| Spacing/S | `gap-2.5` / `p-2.5` | 10 |
| Spacing/M | `gap-3` / `p-3` | 12 |
| Spacing/L | `gap-4.5` / `p-4.5` | 18 |
| Spacing/XL | `gap-7.5` / `p-7.5` | 30 |

## Radii
| Figma | NativeWind | px |
|---|---|---|
| Radius/Card | `rounded-2.5xl` | 20 |
| Radius/Sheet | `rounded-3xl` | 24 |
| Radius/Pill | `rounded-rumor-full` | 128 |

Always pair `borderRadius` with `borderCurve: 'continuous'`.
