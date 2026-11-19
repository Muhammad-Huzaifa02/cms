# DESIGN — CMS visual system

## Brand palette (`core/theme/app_theme.dart` → `AppColors`)

- `brandDeep` — deep green, primary dark
- `brand` — mid green, primary
- `brandLight` — lighter green, gradient endpoint
- `gold` — accent (FAB, highlights, "reveal" actions)
- `ink` — primary text
- `muted` — secondary/label text
- `danger` — errors, destructive actions
- `bg` — screen background (soft off-white)

Headers and hero surfaces use a diagonal `brandDeep → brand` gradient.
The app icon (customer card + magnifying glass, green/gold) is the
visual anchor — reused as a subtle rotated watermark on the Dashboard
header and Login screen.

## Component library (`core/widgets/`) — reuse these, don't re-derive

- **`GlassContainer`** / **`GlassScaffoldBackground`** (`core/widgets/glass_container.dart`) — the
  foundation of the app's modern Frosted Glass design language. Delivers
  hardware-accelerated `BackdropFilter` Gaussian blur (20px), translucent
  acrylic gradient fill (88% to 70% opacity), crisp specular light borders
  (1.5–2px, 95% opacity), and vibrant ambient mesh radial orbs.
- **`SectionCard`** + **`SectionHeader`** — frosted glass card grouping related
  fields/controls (Details, Change Password, Biometric, etc.) with acrylic
  translucency and specular highlighting. Any new settings-style screen
  should be built from this, not a hand-spaced `Card`.
- **`AccountField`** — frosted labeled input with a consistent read-only/"LOCKED"
  treatment and glass borders, used across My Account and similar forms.
- **`PrimaryButton`** — full-width, 52dp, built-in loading spinner. Every
  submit/save button in the app should be this, not a one-off
  `ElevatedButton`.
- **`FeedbackText`** — inline success (green, check icon) / error (red,
  warning icon) line under a form.
- **`TiltTapCard`** — wraps a card with a physical press-down (scale +
  slight 3D tilt) on tap. Used for customer list tiles.
- **`FadeInSlide`** — fade + slide entrance with a genuine, working
  `delay` (staggers multiple elements). Uses `easeOutCubic`, which never
  overshoots past 1.0 — safe to feed straight into `Opacity`.
- **`Perspective3DRoute`** / `push3D()` — the app's standard screen
  transition: a rotateY perspective fly-in, replacing the flat default.
  Used for all forward navigation; plain `pop()` stays default.
- **`ShimmerLoading`** — skeleton loading state (via the `shimmer`
  package) instead of a bare spinner, used on the Dashboard's initial
  customer list load.
- **`Unified Avatar System`** — standardized circular avatar design across
  Staff, Admin, and Customer components featuring a crisp specular white
  border (`1.5–2px`, 85% opacity), drop shadow (`blurRadius: 6–8px`, `offset: 0, 2–3`),
  2-letter bold uppercase initials, and role-matched dynamic gradients
  (Luxury Gold for Admin, Emerald/Sapphire/Teal/Amber/Indigo for Staff & Customer).
- **`Vertix-Inspired Modern Glassmorphism Floating Sidebar`** — high-luxury
  floating frosted glass navigation panel (`borderRadius: 30`, `BackdropFilter` 28px blur,
  obsidian-emerald acrylic tint matching the app's executive palette, radiant atmospheric
  brand glow orbs, and specular light border). Recreates the modern floating workspace aesthetic
  while retaining 100% of the actual CMS operational options, names, and version numbering:
  - **Top Workspace Header**: Circular brand emblem with banking shield icon + full title `CUSTOMER MANAGEMENT SYSTEM` and `CMS • Branch Workspace` + circular white floating close button (`<`).
  - **Quick Search Pill**: Frosted glass capsule text field (`Search customer...`) with search icon and clean chevron linking directly to `SearchCustomerScreen`.
  - **Categorized Sections & Real Options**:
    - `OVERVIEW`: Glowing stadium highlight pill (`borderRadius: 20`) for active `Dashboard`, and `Customer Management` (`Search & view records`).
    - `ADMINISTRATION`: `Staff Management` (`Roles, accounts & permissions`) and `Activity Audit Log` (`Security & compliance trail`).
    - `DATA & EXPORT`: `Export to Excel (.xlsx)` (emerald green), `Export to PDF Document` (coral red), and `Backup Database (.json)` (azure blue).
    - `SYSTEM MAINTENANCE`: `Sync Search Index` (gold shield).
  - **Bottom Profile & Sign-Out**: Circular avatar with green online badge dot (`●`), user full name, email/phone, role badge, dedicated frosted glowing `Sign out` button, and version branding `CMS v1.0.0 • Secured Banking Portal`.

- **`Shared-Axis 3D Banking Page Route`** (`Perspective3DRoute`):
  Elevates incoming screens along the Z-axis (scale from 0.94 -> 1.0, slide up
  0.04 -> 0.0 with `Curves.fastLinearToSlowEaseIn`), while outgoing background
  screens recess to 0.96 scale with frosted glass dimming.
- **`Golden Star Micro-Burst`** (`GoldenFavoriteButton`):
  Explosive micro-particle starburst with 7 radiating gold spark rays and an
  elastic bounce (`Curves.elasticOut`) when favoriting a customer in detail and management views.
- **`Holographic Fingerprint Scan Beam`** (`_HolographicFingerprintScanner`):
  Biometric lock screen featuring vertical oscillating laser scan line, glowing
  aura trails, expanding concentric radar ripples, and tactile touch scale.
- **`Live Audit Ledger & Chronological Timeline Nodes`** (`ActivityLogScreen`):
  Real-time chronological timeline stems, animated entrance cascade, action badges,
  and pulsing live radar nodes (`_LiveLedgerPulseNode`) for real-time compliance events.
- **`Animated Checkmark Draw & Form Progress Bar`** (`AnimatedCheckmark`):
  Form inputs in `AddCustomerScreen` dynamically calculate progress (`0/7` -> `7/7`),
  drawing crisp SVG green checkmarks into field suffixes as validation passes.
- **`Slide-to-Authorize Vault Release Slider`** (`SlideToAuthorizeSlider`):
  High-risk destructive actions (permanent customer deletion) use a tactile slide-to-authorize
  track with expanding red progress gradient and auto-reset springs.
- **`Aurora Mesh Ambient Glow Header`** (`AuroraHeaderBackground`):
  Dashboard app bar features gently oscillating emerald and gold radial aura spheres
  with sinusoidal curves, giving the top banking header a living specular ambient depth.
- **`Dynamic Status Badge Shimmer Sheen`** (`ShimmerSheenBadge`):
  Customer cards across the dashboard feature a periodic diagonal frosted light sheen
  gliding over active status pills every 4 seconds.
- **`Tactical Spring-Stagger on Search Fields`**:
  Search field selector cards in `SearchCustomerScreen` cascade into view with a 60ms
  progressive vertical fly-in and tactile press scaling.
- **`Cryptographic Checksum Copy Ripple`**:
  Tapping account number, IBAN, or CNIC detail tiles flashes the tile with an emerald
  confirmation sheen and morphs the copy icon into an animated checkmark.
- **`Executive Permission Shield Morph & Glow Pulse`** (`AnimatedPermissionChip`):
  Permission chips in `StaffManagementScreen` trigger an interactive spring bounce
  and expanding emerald confirmation ring upon authorization changes.
- **`Floating Staggered Staff Roster Entrance`**:
  Staff cards enter `StaffManagementScreen` with alternating directional fly-in
  and 45ms progressive stagger delays.
- **`Cryptographic Hardware Integrity Badge`** (`CryptographicIntegrityBadge`):
  Floating 256-bit hardware verified ledger badge with gentle 3800ms sinusoidal
  breathing emerald aura and rotating micro-lock on `CustomerDetailScreen`.
- **`Glass Orbit Dual-Bead Spinner`** (`GlassOrbitSpinner`):
  Dual orbiting gold and emerald beads rotating within a frosted glass pill.
- **`PrimaryButton` Micro-Haptic Spring & State Morph**: Features tactile
  spring scaling (`0.96` on touch-down) and smooth `AnimatedSwitcher` morphing
  between the button text and circular progress indicator.
- **`_SlidingGlassFilterBar`**: Sliding frosted glass capsule with continuous horizontal
  interpolation and haptic feedback between "All Customers" and "Favorites" in `CustomerManagementScreen`.
- **`_CryptographicVaultSealingDialog`**: Rotating emerald and gold vault seal modal
  with real-time cryptographic fingerprint calculation during report and database exports.
- **`Dashboard Scroll FAB Motion`**: Animated slide & scale hiding the Floating Action
  Button during fast downward scrolling, restoring immediately upon upward deceleration.
- **`Hero Profile Transitions & 3D Tilt`**: Smooth shared element flight on customer avatar
  from Dashboard to `CustomerDetailScreen` with responsive interactive 3D perspective tilt.
- **`DashboardStatCard`** / `DashboardStatSkeleton` — animated count-up
  stat with icon, accent colour and optional caption.
- **`QuickActionCard`** — compact tappable shortcut tile; only wire it to
  screens that actually exist.
- **`ErrorStateWidget`** / **`SliverErrorState`** — error message with a
  Try Again button. Use whenever a stream/future can fail, so a failure
  is never shown as an empty list.
- **`AccountField`** now takes optional `validator`, `inputFormatters`,
  `hintText`. Passing a validator makes it a `TextFormField`; omitting it
  keeps the plain `TextField`. Use it for every labelled form field
  rather than a screen-local text-field helper.

## Universal Standard Text Scaling & Display Normalization

In financial banking apps with dense, multi-field customer forms, phone/CNIC/account
numbers, and status badges, arbitrary OS-level accessibility font enlargement
causes severe visual clipping, layout overflow exceptions, and truncated data.
The app enforces **`TextScaler.noScaling` (1.0)** via `MediaQuery` in `main.dart`,
ensuring 100% predictable, pixel-perfect rendering across all Android OEM distributions
(Samsung OneUI, Xiaomi MIUI, Oppo ColorOS, Stock Android) without any unintended clipping.

## A recurring bug class — read before adding a new animation

**Never feed a raw `Curves.easeOutBack` / elastic / bounce-curve value
directly into an `Opacity` widget.** These curves intentionally
overshoot past `1.0` (and can go negative) to produce their springy
effect — `Opacity` requires exactly `0.0–1.0` and throws otherwise. This
exact bug has appeared **three separate times** in this codebase. Always
clamp: `opacity: value.clamp(0.0, 1.0)`. The overshoot is fine to use
unclamped for `Transform` (rotation/scale) — just not `Opacity`.

## Layout conventions

- Card corner radius: 15dp (global theme default).
- Input corner radius: 12dp.
- Screen horizontal padding: 16dp.
- Section spacing: 16dp between cards, 16–20dp inside a card between
  fields.
- Dashboard header: 138px `SliverAppBar` `expandedHeight` — this was
  regressed to 200px once already by a careless header rebuild; keep it
  compact, and keep the greeting text at 18–19sp, not 22–26sp.
- Long text (customer names, account titles) must always have
  `maxLines` + `TextOverflow.ellipsis` — a customer name with no
  overflow protection has caused a real silent-clipping bug before.
