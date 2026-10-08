# Design premium pass — branding slice (arena/9ff86ab5-igra)

Status: PARTIAL. Only the branding item of the brief is executed. The palette, typography,
icon, shader, parallax, emblem and HUD items are NOT done in this pass (see Deferred).

## Branch and zone deviations (read first)

- The brief asked for branch `design/premium-v1` in a separate clone. This session is fixed to
  `arena/9ff86ab5-igra`, so all work is on that branch. Nothing was pushed to any other branch.
- The brief's zone `scripts/ui/menu/**` and `scripts/ui/hud/**` does not exist in the repo.
  The main-menu logic lives in `scripts/ui/main_menu.gd`, and it was edited there.
- `docs/RUN_STATE.md`, `CORRECTION_LOG.md`, `ORDER_PASS_REPORT.md`, `PROOFS.md` were not touched.
- The brief's `docs/AGENT_ZONES.md` assigns `project.godot` and `export_presets.cfg` to the lead.
  Both were edited for the window and export title only, and this is flagged for the merge pass.

## Brief item 1 — branding: "Last Streetlight"

| # | File | Before | After | Canon / reason | Expected effect |
|---|---|---|---|---|---|
| 1 | data/i18n/en.json | menu_title `THE LAST STREETLIGHT` | `Last Streetlight` | brief item 1 | EN main menu title and EN store title read the display name |
| 2 | data/i18n/*.json (13 files) | no key | new `boot_title` = `Last Streetlight` | brief: boot/title screen shows the display title; boot_title is an allowed key | boot/title screen shows the brand untranslated in every locale |
| 3 | scripts/splash.gd L28 | `t("menu_title")` | `t("boot_title")` | item 1 | boot/title screen shows the brand, not the localized menu title |
| 4 | scripts/ui/main_menu.gd `_apply_localization` | scene literal (`THE LAST` / `STREETLIGHT`, two lines, English, never localized) | title text = `t("menu_title")` set per locale | item 1, main menu | one-line main-menu title that follows the active language |
| 5 | scenes/ui/main_menu.tscn Title | `THE LAST\nSTREETLIGHT` | `Last Streetlight` | item 1 | scene literal matches the brand string |
| 6 | scenes/ui/splash.tscn Title | `THE LAST STREETLIGHT` | `Last Streetlight` | item 1 | literal matches (splash overrides at runtime) |
| 7 | scenes/ui/menu.tscn, scenes/ui/credits.tscn | `THE LAST STREETLIGHT` | `Last Streetlight` | item 1 | literals match |
| 8 | project.godot `config/name` | `The Last Streetlight` | `Last Streetlight` | item 1, window title | OS window title is the display name |
| 9 | export_presets.cfg product_name, file_description | `The Last Streetlight` | `Last Streetlight` | item 1, store/build title | built app name matches |
| 10 | store/listing.md EN master + EN block | `The Last Streetlight` / `THE LAST STREETLIGHT` | `Last Streetlight` | item 1, store title | EN store title matches |

Localized store titles keep their translations (`menu_title` of each locale, unchanged).
They keep the same name-format as the EN display name. Title case was NOT forced onto them,
which would have been wrong for Russian grammar (ПОСЛЕДНИЙ ФОНАРЬ → «Последний Фонарь»).

## Measured and verified without Godot

- `tools/qa_sim/i18n_truth_gate.py`: 12/12 locales PASS.
- `tools/i18n_audit.py`: 405 keys used, MISSING 0. 13-locale key parity: True (1526 keys).
- `tools/qa_sim/hardcoded_text_gate.py`: exit 0.
- `tools/gen_store_listing_locales.py --check`: GREEN.
- `tools/check.sh --static`: 38 passed, 1 failed (`af3_frame_check`, pre-existing, see below).
- The visual truth gates need numpy. They pass after `pip install numpy pillow`, which is an
  environment issue and is not related to this change.
- Pre-existing failure, not caused by this change: `af3_frame_check` (frame hashes do not
  resolve to commits in this clone).

## Not verified here (visual proof DEFERRED to the merge pass)

- Whether "Last Streetlight" fits the 360 px menu column. Bebas Neue is caps-only, so the title
  renders in uppercase on screen. Its Latin advance width was measured with fontTools: ~282 px at 44 px and 1.15x scale for EN.
- Russian, Japanese, Korean, Chinese, and Arabic titles. Bebas Neue has NO glyphs for Cyrillic or
  CJK or Arabic (cmap check), so these titles fall back to another font. That is a pre-existing
  risk. It was not measured.
- No screenshot was taken, and no visual claim is made.

## Deferred (not done in this pass)

- Palette, typography (one display face plus one UI face, license record), 4/8 px spacing grid,
  unified icon set, menu parallax and glow, minimal HUD, and emblem loading screen. None of
  these were started.
- Shop buy-button UI, skill-tree UI, and all i18n keys other than menu_title, boot_title and the
  store titles. These are owned by the other agent. Deferred-to-merge: `SHARE_TEXT` (contains the
  old display name, still reads `THE LAST STREETLIGHT`).
- The brief's bundled font check. Only the four existing fonts are used. No new font was added.

## Skill invocations (logged)

- ponytail: applied to every edit (minimal diff, reuse of existing keys and paths).
- ponytail-review: manual pass over the diff before each commit (no new abstractions, no deletions needed).
- godot-style: manual pass over the 2 .gd edits (typed `var title := ... as Label`, no polling, no new files).
- arena: run for the title decision with `--agents 4`. Verdicts were written by the orchestrator
  (not independent judges), so they are advisory only. Round 2 did not close and was not finished.
  The decision above was NOT taken from the arena's verdict alone.
- graphify: not invoked (no graphify-out and no UI dependency sweep was run).
- omniroute: not invoked (no sub-agent routing was needed).

## Change log

- Commit 1: branding strings and literals (items 1-10 above).
- Commit 2: this document.
