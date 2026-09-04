# GraceGrid Sanctuary — UI Build Context (for Antigravity)

Source design: Stitch export `stitch_faithconnect_bible_community/` (8 screens as HTML/Tailwind mockups + PNG previews + `digital_sanctuary/DESIGN.md` design tokens). This file translates that export into a Flutter build brief. Target stack: **Flutter + Riverpod**, dark theme only (no light mode in the source design).

App identity in mockups: "GraceGrid Sanctuary" — internal project name is GraceGrid.

---

## 1. Auth model — READ FIRST, this changes several screens

**Confirmed product rule:** Bible reading and Sermon notes work with **zero login**. Login is required only when the user touches a **Community** or **Fellowship** feature (feed post/like/comment/follow, prayer wall post, live rooms, 1:1 voice/video calls, live chat).

Implementation implication for the UI:
- App opens straight into the **Bible tab** — no auth gate, no splash-to-login redirect.
- Bottom nav (5 tabs, from mockups: `bible`, `sermons`, `live`, `feed`, `profile`) is visible immediately. `bible` and `sermons` are always tappable.
- Tapping `live`, `feed`, or any social action (like, comment, follow, post, join call) while unauthenticated triggers **soft-gate**: present the Login/Signup screen (spec in §4) as a modal/bottom-sheet-style push, not a blocking first screen. On success, return the user to the action they attempted.
- `profile` tab: unauthenticated state shows a lightweight "Continue as Guest" summary (local stats only — verses read, notes taken) with a prompt to sign in to unlock Community. Authenticated state shows the full `believer_profile_journey_hub` screen.
- Use Firebase Anonymous Auth silently in the background from first launch so local Hive data (highlights, bookmarks, notes) can be upgraded via `linkWithCredential` the moment the user signs up — avoids a "merge my data" flow later. This is a data-layer decision, not a UI one, but it means the signup screen must support **account linking**, not just fresh account creation.

---

## 2. Design tokens (from `digital_sanctuary/DESIGN.md`)

Theme name: **Digital Sanctuary** — dark, glassmorphic, "cyber-sanctuary." Map directly to a Flutter `ThemeData`/`ColorScheme`:

**Core colors**
- Background / surface: `#0D1511` (base), `#08100C` (lowest), `#151D19` (low), `#19211D` (container), `#242C27` (high), `#2E3732` (highest)
- Primary (Neon Holy Emerald): `#76FFAF` (primary), `#00E68A` (primary-container), `#00391E` (on-primary)
- Secondary (Ethereal Teal): `#4CD7F6` (secondary), `#03B5D3` (secondary-container)
- Tertiary: `#72FEC0`
- On-surface text: `#DCE5DD` (primary text), `#BACBBC` (variant/muted text)
- Outline: `#849587`, outline-variant `#3B4A3F`
- Error: `#FFB4AB` / container `#93000A`

**Typography** — two font families:
- Headlines/labels/buttons: **Plus Jakarta Sans** (weights 600–800), tight letter-spacing (-0.01 to -0.03em on large sizes)
- Body/scripture/devotional copy: **Inter** (400 weight), generous line-height (1.5–1.65)
- Scale: display-lg 44/52, headline-lg 30/38, headline-md 22/28, headline-sm 18/24, scripture-quote 17/28 (Inter, slightly tinted ivory `#ECFDF5`), body-lg 16/24, body-md 14/20, label-md 13/16 (tracked +0.04em), label-sm 11/14 (tracked +0.08em)
- In Flutter: use `google_fonts` package for both families rather than bundling font files, unless offline font loading is a requirement — flag this to Kayode if bundling is preferred for offline-first reliability.

**Shape**
- Inputs/buttons/list items: 8px radius
- Cards/modules: 16px or 24px radius
- Badges/pills/status tags/avatars: full capsule (`9999`)

**Elevation (no drop shadows — use layered translucency + blur instead)**
- Glass Level 1 (default containers/list tiles): surface at ~75% opacity, `blur(12px)`, 1px border `rgba(16,185,129,0.15)`
- Glass Level 2 (interactive cards/floating bars): ~85% opacity, `blur(16px)`, border `rgba(0,230,138,0.25)`, ambient halo shadow
- Glass Level 3 (modals/overlays/active focus): ~95% opacity, `blur(24px)`, high-contrast rim `rgba(0,230,138,0.40)`
- In Flutter: `BackdropFilter` + `ImageFilter.blur` + semi-transparent `Container` with `Border` — build a shared `GlassCard` widget once, reuse everywhere, rather than re-implementing per screen.

**Components to build as shared widgets (used across multiple screens):**
- `PrimarySanctuaryButton` — solid `#00E68A` fill, dark text, glow on press
- `GhostButton` — translucent emerald fill, emerald border/text
- `GlassCard` (see above, 3 elevation variants)
- `LiveBadge` — pill with pulsing red dot + "LIVE" label
- `TopicFilterChip` — capsule, selected = emerald glow
- `BottomNavBar` — 5 tabs: Bible (`menu_book`), Sermon (`mic`), Live (`live` — likely camera/broadcast icon), Feed (`feed` — likely a feed/list icon), Profile (avatar)
- Icons throughout mockups use **Material Symbols Outlined** — use `material_symbols_icons` package or Flutter's built-in Material icon set with closest matches (`menu_book`, `mic`, `auto_stories`, `volume_up`, `cloud_done`, `notifications`, etc.)

---

## 3. Screen inventory (build in this order to match the phase plan)

Each has a `code.html` (Tailwind reference markup) and `screen.png` (visual reference) in the export — feed both to Antigravity per screen for pixel reference.

| Screen folder | Maps to phase | Purpose |
|---|---|---|
| `bible_reader_deep_study` | Phase 1 (Bible) | Main scripture reader — passage picker, translation switcher (e.g. "WEB"), font-size + reading-mode (Sanctuary/Sepia) settings sheet, offline-ready indicator ("Offline Ready • 2.4 MB"), audio playback toggle |
| `sermon_studio_live_notes` | Phase 2 (Journal) | Live note-taking during a sermon — includes a recording clock (`rec-clock`), implies audio-record UI is inline with note editor |
| `believer_profile_journey_hub` | Phase 1 guest / Phase 3 full | Profile screen — reading streaks, journey stats; needs a guest-mode variant per §1 |
| `sanctuary_community_feed` | Phase 3 (Community) | Main social feed — posts, prayer requests, testimonies, likes/comments implied by feed card pattern |
| `1_to_1_fellowship_prayer_chat` | Phase 4 (Fellowship) | 1:1 text chat screen, prayer-focused |
| `1_to_1_voice_prayer_call_audio_sanctum` | Phase 4 (Fellowship) | 1:1 voice call UI ("Audio Sanctum") |
| `1_to_1_video_fellowship_call` | Phase 4 (Fellowship) | 1:1 video call UI |
| `live_fellowship_worship_room` | Phase 4 (Fellowship) | Group live room (worship/live session) |
| `gracegrid_sanctuary_logo` | Branding | Logo asset reference only |

**Not in the export — needs to be built new:** Login/Signup screen (spec below).

---

## 4. Login / Signup screen — new spec (matches Digital Sanctuary system)

Since this doesn't exist in the Stitch export, build it consistent with the existing tokens so it doesn't look bolted on.

**Presentation:** Modal bottom-sheet or full-screen push triggered by the soft-gate in §1 — NOT the app's first screen.

**Layout (single screen, tab-switchable between Login/Signup):**
- Glass Level 3 container (modal elevation) on the standard `#0D1511` background with the same ambient emerald/teal radial glow blur used on the Bible reader
- GraceGrid logo + "Sanctuary Live" pulse dot at top (reuse header brand mark from existing screens)
- Headline (headline-md, Plus Jakarta Sans): "Join the Fellowship" (signup) / "Welcome Back" (login)
- Sub-copy (body-md, muted `on-surface-variant`): explain *why* — e.g. "Sign in to post, pray with others, and join live rooms." (Reassures the user this isn't gating the Bible.)
- Segmented toggle (capsule, emerald active state) between **Log In** / **Sign Up**
- Input fields (per Input Fields token: `#070E0A` fill, `rgba(16,185,129,0.2)` border, emerald focus ring):
  - Email or phone number
  - Password (signup adds: confirm password)
  - Signup only: Display name
- Primary Sanctuary Action button: "Continue" / "Create Account" (full width, emerald, glow on press)
- Divider: "or continue with"
- Secondary/Ghost buttons: Google, Apple sign-in (translucent emerald outline style, per Secondary Ghost Action token)
- Footer link (ghost/tertiary style): "Continue browsing as Guest" — dismisses the sheet and returns the user to read-only Bible/Journal use, reinforcing no-login-required
- Error states use the `error` / `error-container` tokens (`#FFB4AB` / `#93000A`), inline under the relevant field, not a toast — matches the app's calm, non-intrusive tone

**States to account for in Flutter widget:**
- Loading (button shows spinner, disabled state)
- Validation error (inline, per field)
- Anonymous-to-authenticated linking success (silent — just closes the sheet and completes the original gated action)
- Network offline (Community/Fellowship auth requires connectivity — show a small inline notice, don't hard-fail the whole sheet)

---

## 5. Build notes for Antigravity

- Convert Tailwind class patterns to Flutter theme extensions once (colors, text styles, radii, spacing) rather than re-deriving per screen — token table in §2 is the single source of truth.
- Treat `code.html` files as **layout/structure reference**, not literal code to port — Tailwind flex/grid patterns map to `Row`/`Column`/`Wrap` + `Expanded`, not a 1:1 translation.
- Bottom nav must be a persistent shell (e.g. `IndexedStack` under a `Scaffold` with `bottomNavigationBar`) so tab state survives navigation, matching the mockups' persistent nav across all screens.
- Build the shared `GlassCard`, button, and chip widgets from §2 **before** starting on individual screens — every screen in the export reuses the same handful of components.
