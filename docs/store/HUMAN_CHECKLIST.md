# Human checklist — things Claude cannot do

## Music credits to retain in the store and distribution (2026-11-10)

Hymn and Moonlight by Scott Buckley, released under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/), www.scottbuckley.com.au. Sources: [Hymn](https://www.scottbuckley.com.au/library/hymn/) and [Moonlight](https://www.scottbuckley.com.au/library/moonlight/). Changes: mono conversion, two-second loop crossfade, 3 ms edge guards, level matching and OGG encoding; no pitch or tempo change. These credits also appear in-game. Other shipped music remains partly AI-generated (Google Lyria); this addition does not remove that disclosure. The ledger and exact file hashes are in `docs/ASSET_LICENSES.md`.

Steps below need a GUI, an account, real credentials, or a build toolchain
this session doesn't have. Everything else (code wiring, config placeholders,
docs) is already done — see `docs/SESSION_REPORT_FINAL.md` for what.

## Android bonus verification

With a release export, open the bonus on cellular, connect to Wi-Fi with no internet, then disconnect. Check the reason beside the button at each step, including on the paused death screen. Inspect the merged release manifest for ACCESS_NETWORK_STATE and VIBRATE and confirm it omits INTERNET and AD_ID.

## Play Store / release

See `docs/release_checklist.md` and `docs/store/play_store.md` for the
already-drafted parts (descriptions, tags, rating notes). Still needs a
human for:
- Google Play Console account + app listing creation.
- Keystore generation for the RELEASE build (a separate one from the debug
  keystore already committed at `res://tls_debug.keystore`):
  ```bash
  keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
  ```
  Store this file and its password outside the repo. Paste the path into
  `export_presets.cfg`'s `keystore/release`/`keystore/release_user`/
  `keystore/release_password` before the final signed build.
  (Done in Session 32 with a fresh key, `docs/RELEASE_ARTIFACTS.md`: the
  bundle of Session 36 is signed with it, and the preset keeps its fields
  empty on purpose because Godot reads the passwords from the environment.
  What is left is to copy `.signing/` off this machine.)
- Data Safety form + IARC content rating questionnaire in Play Console
  (notes on expected answers already in `docs/store/play_store.md`).
- Publish the updated English and Russian policy from `store/privacy-policy-template.md` at https://maxxxxx55555.github.io/igra/. Set both data collected/shared and contains ads to No in Play Console.
- AI-generated content answer (Play, Steam): yes. The music (12 tracks, Gemini app, Google Lyria) and the pre-made images (`docs/ART_PASS_2.md` and the earlier rows of `docs/ASSET_LICENSES.md`) are AI-generated; nothing is generated at run time; the credits (`CREDITS_MUSIC`, `CREDITS_ART`) and the listing's AI line say so. Say it in those words and do not call the art hand-made (the Google Terms of Service forbid presenting generative AI content as human-made).
- Upload to an internal/closed testing track before production.
- **Music licence (Session 27; decided in Session 37: A, ship the tracks labelled as AI, `docs/MUSIC_RIGHTS_MEMO.md`; the owner may veto, and the way back is below).** The 12 music tracks were made in the Gemini app (Google Lyria, SynthID-watermarked). Google's Terms say Google claims no ownership of content created with its services and say
  nothing on commercial use of Gemini-app music, so the rights are not verified here (`docs/ASSET_LICENSES.md`, section "Session 27 M1"). Read the Gemini Apps terms of your account and accept them, or replace the files
  (`docs/GEMINI_HANDOFF.md` lists the targets and prompts). The way back is git: the eight district tracks are the lit beds named in `AMBIENCE_LIT_BY_DISTRICT`; the synthesized `*_lit.ogg` they replaced and `music_boss_dark.wav` were deleted in the v10 pass
  (`git show 3ca44bb:<path>` brings one back, then point its entry back); for the menu move
  `_QUARANTINE/assets/audio/music/abandoned_hallways.mp3` back and point `Mood.MENU` at it (one line).

## CC0 asset reference repo (TRUTH WAVE ask)

Was asked to search `..\refs\` and `.claude/skills/` for a CC0 asset/
pattern reference repo (examples given: something matching "ponytail",
or Polyhaven/Kenney asset packs). Checked both — `..\refs\` only
contains `AppLovin-MAX-Godot`, `escoria`, `godot-admob`,
`godot-demo-projects`, `godot-docs`, `godot-open-rpg`, `ink`; `.claude/
skills/` only has the `ponytail` family of *review/workflow* skills
(over-engineering audits), not an asset pack. **No matching CC0 repo
exists in this checkout.** If one should be added, please paste the
exact URL (Polyhaven, Kenney, or otherwise) and it can be cloned into
`..\refs\` per the existing convention.

## Play Store rating change (PEGI 16, was PEGI 12)

This pass's store-copy rewrite changed the expected rating from PEGI 12
to **PEGI 16** per explicit instruction, citing the game's blood/bleed
status effects and the disaster's deliberate-mass-casualty narrative
thread. This is a judgment call on borderline content, not a GDD fact —
worth a second look before actually submitting the IARC questionnaire;
if the intent is PEGI 12, revert `docs/store/play_store.md`'s "Rating
note" and the equivalent line in `docs/store/steam.md`.

## RESCUE WAVE delta

- P2.6 (UI chrome kit / StyleBoxTexture on main menu/pause/inventory)
  needs OpenCode B's chrome-kit delivery before it can be integrated —
  nothing to wire yet.
- P2.7 (map/minimap district crest icons) — **done**: 23 crest textures live in
  `assets/textures/crests/` and `scripts/ui/city_map.gd` loads them per district
  (`res://assets/textures/crests/crest_<id>_96.png`, guarded by `ResourceLoader.exists`).
- Draw-call budget — **closed (2026-11-09)**: the windowed GPU perf gate reads 103 draw calls
  in the suburbs and 111 in the power station, inside the GDD's budget (<200 D1, <350 D11),
  with p95 24.09 / 28.33 ms against a 33 ms budget. The old "370 in the spawn district"
  reading is superseded; the MultiMesh streetlight conversion is no longer needed for the
  budget. Root cause and history remain in `docs/KNOWN_ISSUES.md`.
- Ponytail/CC0 asset-reference repo: still not found in `..\refs\` or
  `.claude/skills/` (same result as the TRUTH WAVE pass) — paste the
  exact URL if one should be added.

## Steam (optional/secondary platform, see `docs/store/steam.md`)

- A Windows Desktop export preset exists and is configured (`export_presets.cfg`, "Windows
  Desktop"), and a release build of it has been produced and smoke-tested (see
  `docs/RELEASE_ARTIFACTS.md`); a Web preset is configured too. Only a **Linux** preset is
  still missing, and only if that platform is actually being pursued.
- Steam's content survey asks about AI-generated content: answer yes for the pre-generated art and music (`docs/ASSET_LICENSES.md`); the credits screen already says the music is AI-generated.
- Steamworks SDK, app ID, and store-page setup are all account/GUI-gated —
  out of scope for this session entirely.
