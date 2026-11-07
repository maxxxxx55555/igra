# UI design review and optimization proposals

Scope: code-based review of the shipped UI (7 November 2026 integration candidate). This is a
design/engineering review, **not** a device or visual acceptance result. No rendered captures,
physical touch measurements or EN/RU screenshot walks were produced in this pass; those remain
release blockers listed in `docs/release/RELEASE_REPORT_2026-11-07.md`.

## 1. What is already strong (preserve)

- **One source of truth for the theme.** `scripts/ui/theme_provider.gd` owns the whole
  charcoal/brass palette (`COLOR_BG_DARK`, `COLOR_AMBER`, `COLOR_DANGER_TEXT`, …) and the licensed
  Bebas Neue / Roboto Condensed / Share Tech Mono faces. Every screen calls `build_theme()`. This
  is exactly the right architecture: changing a token changes the entire UI family consistently.
- **Central safe-area and scaling math.** `scripts/ui/ui_scale.gd` exposes `insets()`, `min_touch()`,
  `narrow_layout()` and `log_map_row()` so the LOG/Map row computes the inset once. The comments in
  `quest_tracker_hud.gd` confirm the "never add the inset twice on resize" rule is understood.
- **Semantic danger colour split.** `COLOR_DANGER` for fills and `COLOR_DANGER_TEXT` for small text
  fixes the classic mistake of using one low-contrast red for both.
- **Real touch mechanics, not button signals.** `scripts/ui/virtual_joystick.gd` tracks
  `_touch_index`, radial dead zone, exponential response curve and hold animation; the HUD rest
  opacity is now `0.8` (`_TOUCH_REST`, `REST_ALPHA`), up from the too-faint `0.55`/`.45`.
- **Shop layout regression fixed.** `scripts/ui/screens.gd` builds cards from content-sized
  `PanelContainer` + `VBoxContainer`, which is why the shop scroll and 7-of-7 catalogue check passes.
- **Quest tracker moved into freed space** after the radar removal (`PANEL_TOP`, `MAX_ROWS`).

## 2. Findings, ordered by impact

### F1 — Touch-target policy is still fragmented (high)
`UiScale.MIN_TOUCH` is 48 logical units, but authored controls differ (side buttons 64×64, pause
36×36, shop Buy 220×44, map actions, quick slots, dialogs). `min_touch()` is applied in only a few
clusters, so some controls still fall below any consistent effective target after stretch scaling.
**Proposal:** introduce one `UiScale.apply_target(control, kind)` helper that resolves the final
rectangle through the viewport/window/canvas transform to device pixels, then compares against the
actual `DisplayServer` density (with an explicit calibrated fallback when density is unreliable).
Route every dynamic button through it. Keep `min_touch()` as the single policy constant and derive
the rest from `kind` (ordinary / movement / fire). Do not hardcode 1600×720 or apply the scale twice.

### F2 — Separate control scale from text scale (high)
`settings_manager.gd` still couples `button_size` and the text scale array `[0.9, 1.0, 1.15]`; the
largest touch default can effectively enlarge the whole window. **Proposal:** two independent
settings, one `ui_control_scale`, one `ui_text_scale`, with a one-time migration that preserves an
explicit user choice and never overwrites it on every boot. `narrow_layout()` should react to the
text scale only.

### F3 — Shared responsive group for the corner overlays (medium-high)
LOG, Map, ammo/attack cluster and the objective panel still have independent absolute anchors
(`LOG_MAP_ROW_TOP`, `PANEL_TOP`, `AmmoCounter`, `Attack`). Overlap under enlarged text or a tall
phone is possible. **Proposal:** one `HudLayout` computation that receives viewport size, insets,
text scale and control scale, and returns rectangles for all four groups; recompute idempotently on
`size_changed`, inset change and settings change. Reserve the action-cluster rectangle before
placing ammo; cap LOG's scroll height to the space above the joystick.

### F4 — Contrast must be measured on the composited frame, not tokens (medium)
Token pairs are chosen well, but parent `modulate`, rest opacity, outlines, background images and
bright world content all change the final ratio. Locked skill cards modulating the whole card to
`.85` also dims the requirement text that must stay readable. **Proposal:** add an automated
composited-contrast probe that samples the final rendered pixels behind each text label at rest and
in disabled/selected states, targeting 4.5:1 normal text and 3:1 for genuinely large text and
essential focus edges. Prefer an opaque local backing panel over heavy outlines. Decouple disabled
decoration from text: modulate the frame, never the label.

### F5 — Information density on sparse screens (medium)
Large skill/shop/achievement panels still read as mostly empty surfaces. **Proposal:** keep the
charcoal/brass frame but add a real two-column hierarchy (selected item inspector + list), inline
requirement/progress blocks and a footer showing the currently affordable action. Use the 4/8/12/16/24
spacing rhythm already established. No fake items, no decorative filler cards.

### F6 — EN/RU completion needs a long-string gate (medium)
Exactly two locales are the owner rule. Russian strings are ~1.3–1.8× longer; several labels are
11–15 logical px. **Proposal:** a headless localization sweep that instantiates every registered
screen with the longest known RU value per key at maximum text scale and reports clipped/overflowing
`Label` rectangles. Never shrink text to hide overflow; reflow instead. Verify selectors,
persistence, export and first launch still expose only `en`/`ru`.

### F7 — State coverage for script-created UI (medium)
Default/hover/focus/pressed/selected/disabled/loading/error states exist for the main theme, but
rare script-created states (toast deferral under a modal, empty/full ammo, locked skill, denied
purchase, failed load) are easy to regress. **Proposal:** extend `ui_layout_check` and `a11y_probe`
with a state matrix that visits each rare state in both languages and at max scale.

### F8 — Duplicate full-screen effects cost (low-medium)
The brief calls for a single grain owner and a Low-tier rain guard. `post_process_overlay.gd`
already hides idle layers (`_sync_chroma` sets `visible = px > 0`), which is the right pattern —
apply the same "hidden means no tick and no draw" rule to the weather overlay on Low and to the
single remaining grain layer, and update the gate that still expects two passes to assert the
correct single-owner behaviour.

## 3. Recommended order

1. F1 + F2 (one sizing/scale policy) — everything else depends on it.
2. F3 (layout recomputation), then F4 (measured contrast).
3. F6 + F7 (state/locale matrix) as regression coverage.
4. F5 + F8 (density and effect cost) as polish.

Each step should be followed by `tools/check.sh --static`, the UI layout / accessibility / touch
gates, and one real windowed EN and RU walk on a phone-sized viewport. Do not weaken an existing
assertion to obtain a pass.

## 4. Explicitly not claimed

No WCAG conformance certification, no measured dp/sp values, no real multitouch hardware result, no
production-art or font-licensing sign-off. Findings F1–F8 are code-derived proposals; they are not
implemented in this candidate unless named in the release report.
