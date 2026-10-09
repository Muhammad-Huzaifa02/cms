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

- **`SectionCard`** + **`SectionHeader`** — titled card grouping related
  fields/controls (Details, Change Password, Biometric, etc.). Any new
  settings-style screen should be built from this, not a hand-spaced
  `Card`.
- **`AccountField`** — labeled input with a consistent read-only/"LOCKED"
  treatment, used across My Account and similar forms.
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

- **`DashboardStatCard`** / `DashboardStatSkeleton` — animated count-up
  stat with icon, accent colour and optional caption.
- **`QuickActionCard`** — compact tappable shortcut tile; only wire it to
  screens that actually exist.
- **`GrowthChart`** / `GrowthChartSkeleton` — dependency-free 7-bar chart
  fed a `List<int>` of daily counts.
- **`ErrorStateWidget`** / **`SliverErrorState`** — error message with a
  Try Again button. Use whenever a stream/future can fail, so a failure
  is never shown as an empty list.
- **`AccountField`** now takes optional `validator`, `inputFormatters`,
  `hintText`. Passing a validator makes it a `TextFormField`; omitting it
  keeps the plain `TextField`. Use it for every labelled form field
  rather than a screen-local text-field helper.

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
