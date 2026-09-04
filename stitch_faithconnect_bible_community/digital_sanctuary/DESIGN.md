---
name: Digital Sanctuary
colors:
  surface: '#0d1511'
  surface-dim: '#0d1511'
  surface-bright: '#333b36'
  surface-container-lowest: '#08100c'
  surface-container-low: '#151d19'
  surface-container: '#19211d'
  surface-container-high: '#242c27'
  surface-container-highest: '#2e3732'
  on-surface: '#dce5dd'
  on-surface-variant: '#bacbbc'
  inverse-surface: '#dce5dd'
  inverse-on-surface: '#2a322e'
  outline: '#849587'
  outline-variant: '#3b4a3f'
  surface-tint: '#00e388'
  primary: '#76ffaf'
  on-primary: '#00391e'
  primary-container: '#00e68a'
  on-primary-container: '#006137'
  inverse-primary: '#006d3e'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#72fec0'
  on-tertiary: '#003824'
  tertiary-container: '#51e1a5'
  on-tertiary-container: '#006141'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#58ffa5'
  primary-fixed-dim: '#00e388'
  on-primary-fixed: '#00210f'
  on-primary-fixed-variant: '#00522e'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0d1511'
  on-background: '#dce5dd'
  surface-variant: '#2e3732'
typography:
  display-lg:
    fontFamily: plusJakartaSans
    fontSize: 44px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: plusJakartaSans
    fontSize: 34px
    fontWeight: '800'
    lineHeight: 42px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: plusJakartaSans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: plusJakartaSans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: plusJakartaSans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  scripture-quote:
    fontFamily: inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: plusJakartaSans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: plusJakartaSans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-xxs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
  space-3xl: 4rem
  margin-mobile: 1rem
  margin-desktop: 2.5rem
  gutter-mobile: 0.75rem
  gutter-desktop: 1.5rem
---

## Brand & Style

This design system constructs a reverent, modern spiritual ecosystem—merging the solemnity and introspection of a physical cathedral with the cutting-edge precision of a futuristic digital hub. It serves believers seeking a refined, distraction-free environment for worship, prayer, scripture study, and communal fellowship.

The aesthetic fuses **Modern Glassmorphism** with an ambient **Cyber-Sanctuary Dark Mode**. Deep, atmospheric obsidian and deep-forest tones form the spatial substrate, while living emerald luminescence and celestial teal light convey renewal, divine grace, and spiritual vitality. Translucent frosted panes, faint edge lighting, and disciplined typography evoke quiet devotion, peace, and sacred gravitas without sacrificing contemporary utility.

## Colors

The color palette translates divine presence into luminescent digital signals set against cosmic, deep-space dark matter.

- **Primary (`#00E68A`)**: Neon Holy Emerald. Symbolizes new life, growth, and divine favor. Used for active tabs, primary call-to-actions, vital indicators, and focal points of prayer or engagement.
- **Secondary (`#06B6D4`)**: Ethereal Teal / Cyan. Represents wisdom, truth, and tranquil sanctuary waters. Used for secondary actions, informational badges, scripture references, and prayer tags.
- **Tertiary (`#10B981`)**: Deep Emerald Foliage. Provides gradient grounding, balanced interactive states, and soft halo rings.
- **Background Surfaces**: 
  - Void Obsidian (`#050907`): Absolute canvas base.
  - Sanctuary Slate (`#0A120E`): Default elevated surface.
  - Forest Canopy (`#0E1A14`): Elevated cards, modals, and navigation panels.
- **Borders & Halo Accents**: Emerald 500 alpha fills (`rgba(16, 185, 129, 0.18)` and `rgba(0, 230, 138, 0.35)`) deliver thin, illuminated perimeter strokes that simulate spiritual luminescence on frosted glass.

## Typography

The typographic hierarchy balances forward-looking technical precision with reverent contemplation. 

- **Headlines & Labels (`plusJakartaSans`)**: Geometric yet humane curves lend modern warmth and optimism to titles, metric counters, button states, and section headings. Tracking is set tighter on larger headers (`-0.03em` to `-0.01em`) for high-impact presence.
- **Body & Devotional Copy (`inter`)**: Neutral, ultra-legible, and unobtrusive. Set with comfortable line-height ratios (`1.5` to `1.65`) to reduce visual strain during prolonged sermon note-taking, biblical reading, and group prayer contemplation.
- **Scripture Passages**: Styled through the `scripture-quote` token, emphasizing breathing room, subtle italicization where appropriate, and soft ivory tinting (`#ECFDF5`) rather than blinding pure white.

## Layout & Spacing

The layout is rooted in an 8-point rhythmic grid, scaling strictly to support serene negative space and focused devotion. 

- **Mobile Viewports (under 768px)**: Standard 4-column fluid layout with `16px` (`1rem`) outer margins and `12px` gutters. Card components collapse into a single-column stacked feed or horizontal carousel (e.g., Live Worship, Prayer Wall cards).
- **Tablet & Split-Screen Viewports (768px - 1024px)**: 8-column layout with `24px` margins and `16px` gutters. Two-column card arrangements accommodate side-by-side Scripture and Notes.
- **Desktop/Expanded Layouts (1024px+)**: 12-column fixed-max layout centered at `1200px` max-width, with `40px` margins and `24px` gutters.

Dynamic mobile paddings preserve bottom navigation clearance (`safe-area-inset-bottom` + `64px`) to ensure seamless interactions during active worship or study sessions.

## Elevation & Depth

Visual hierarchy does not rely on harsh drop shadows; instead, it is manifested through **luminous surface layering** and **frosted glassmorphism**.

1. **Base Layer (Canvas)**: Hex `#050907` with subtle radial emerald and teal light leaks (`rgba(0, 230, 138, 0.04)` and `rgba(6, 182, 212, 0.03)` with `120px` blur).
2. **Glass Level 1 (Default Containers & List Tiles)**: Semi-translucent `#0A120E` at 75% opacity, `backdrop-filter: blur(12px)`, bordered by a 1px solid stroke of `rgba(16, 185, 129, 0.15)`.
3. **Glass Level 2 (Interactive Cards & Floating Bars)**: `#0E1A14` at 85% opacity, `backdrop-filter: blur(16px)`, bordered by `rgba(0, 230, 138, 0.25)`, coupled with an ambient halo shadow: `0 8px 32px -4px rgba(0, 230, 138, 0.08)`.
4. **Glass Level 3 (Modals, Active Focus & Overlays)**: `#0E1A14` at 95% opacity, `backdrop-filter: blur(24px)`, edged with a high-contrast rim of `rgba(0, 230, 138, 0.40)` and an outer bloom: `0 12px 40px 0 rgba(0, 230, 138, 0.16)`.

## Shapes

The shape system employs rounded geometry (`level 2`) to instill harmony, welcome, and safety. 

- Standard inputs, buttons, and individual list items use `0.5rem` (8px).
- Feature cards, sanctuary modules, prayer cards, and interactive banners scale to `1rem` (16px) or `1.5rem` (24px) for prominent boundaries.
- Badges, status tags (e.g., "LIVE", "WAITLIST"), icon circular plates, and pill pills leverage full capsules (`9999px`) to visually soften status messaging.

## Components

### Buttons
- **Primary Sanctuary Action**: Solid neon emerald background (`#00E68A`) with high-contrast obsidian typography (`#050907`), bold weight. Subtle inner bevel (`inset 0 1px 0 rgba(255, 255, 255, 0.3)`) and outer glow hover effect (`box-shadow: 0 0 20px rgba(0, 230, 138, 0.4)`).
- **Secondary Ghost Action**: Translucent dark green surface (`rgba(16, 185, 129, 0.1)`) with `1px` border of `rgba(0, 230, 138, 0.3)`, text in `#00E68A`.
- **Tertiary Subtle**: Pure transparent fill, icon and label in light mint slate (`#A7F3D0`), changing to `#00E68A` on press.

### Cards
- **Frosted Sanctuary Cards**: Constructed with glass elevation level 2. Includes an optional subtle top-edge gradient highlight (`linear-gradient(90deg, rgba(0, 230, 138, 0.3), rgba(6, 182, 212, 0.1), transparent)`). Used for Bible reader modules, live worship cards, and sermon notes.
- **Prayer Wall Cards**: Feature a dedicated devotional quote or prayer intention, complemented by an interactive glowing "Amen" or prayer counter pill on the bottom right.

### Input Fields
- Deep obsidian-forest fill (`#070E0A`) with 1px border in `rgba(16, 185, 129, 0.2)`. Placeholder text in muted teal gray (`#6EE7B7` at 40% opacity). Upon focus, border transitions smoothly to `#00E68A` paired with a soft ambient aura (`box-shadow: 0 0 0 3px rgba(0, 230, 138, 0.15)`).

### Chips & Badges
- **Live / Active Badge**: Pill shape with crimson-emerald dual indicator: `#EF4444` live dot paired with a frosted emerald container (`rgba(0, 230, 138, 0.12)`).
- **Topic Filter Chips**: Capsule shaped, 1px perimeter in `rgba(255, 255, 255, 0.08)`. Selected state shifts to `#00E68A` text with an emerald glow surface.

### Checkboxes & Toggle Switches
- Checkboxes: 20px rounded squares (radius `6px`) in dark slate. Checked state fills with `#00E68A`, displaying a dark `#050907` checkmark.
- Toggles: Pill track in `#0E1A14`. When activated, track glows emerald with a pure white circular thumb.

### Scripture Reader Pane
- Dedicated reading container offering custom serif/sans-serif toggling, elevated contrast ratios, adjustable line height, and delicate glowing horizontal separators separating chapter verses.