# Player-visible changes

Running log, newest batch first. Written for the owner doing manual
in-game verification — a static-only pass can't play the game itself.

---

## Batch 8 (2026-09-10) — FINAL RC: Arena mega final pass (PR #9)

- **Three lore notes now end on a quotable line** (in every one of the
  13 languages, not just English):
  - *"Photo: The Carousel in Summer"* (Park) — adds: "Nobody in the
    queue knew the order would never be given again."
  - *"Radio: 'Go to the Power Station'"* (Park) — last line changed from
    "The voice is the same one as the manifesto's seal" to "The voice
    belongs to whoever pressed the seal." (fixes a mixed metaphor;
    points at the Keeper's seal, which is already canon).
  - *"Photo: Locker 12, Seized Lamps"* (Police) — adds: "The property
    book has never cleared six items faster."
- **No gameplay, stats, ids or save format changed** — text only.
- **Store / marketing kit finished (not in-game):** `store/trailer/` now
  holds 5 ship-ready key-art masters (3 wow-moment stills, 1 vertical
  Shorts frame, 1 press-kit header), plus `store/trailer.md` (trailer
  edit plan), `store/press-kit.md` (fact sheet + reviewer email), and
  `store/listing.md` polish. Nothing here ships in the APK; it's for the
  Play Store listing, the trailer editor, and press outreach.

### HUMAN CHECK (1 min, optional)
Open the Journal in-game, set the language to a few different locales,
and read those three notes (Park carousel photo, Park radio, Police
locker photo). Each should end on the new closing sentence, in-language,
with no clipped text.

---

## Batch 7 (2026-09-10) — RC final pass (STATIC_AUDIT close-out + PR #8 merge)

- **District-restore notification is no longer doubled.** Restoring a
  district to FULL used to pop two overlapping toasts — a translated
  "District saved: <name>" *and* an always-English "District restored!".
  Now just the single translated one.
- **Puzzle and daily-event notifications are translated now** (were
  hardcoded English in every language): the substation cable-box puzzle
  rewards ("+N coins", "Battery/Medkit found!", "Reactor online!") and
  the daily-event start/end toasts.
- **New accessibility option — Settings → Accessibility → "Reduce Screen
  Shake".** When on, the camera stops shaking on hits and enemy deaths.
  Off by default (no change unless you turn it on). Available in all 13
  languages.
- **Two lore notes read "center" instead of "centre"** (English text
  only) — the gas-station "Requisition, Countersigned" and police
  "Property Release, Countersigned" notes. Spelling consistency with the
  other 24 in-world uses; no other locale affected (French keeps
  "centre", which is correct French).
- **No functional/gameplay change** otherwise. Debug text was removed
  from the log output on district entry / photo capture / crafting —
  invisible to players, listed for completeness.
- **Store-submission kit** added under `store/` (listing EN+RU,
  changelog, 1024×500 feature graphic, 512×512 icon, screenshots plan,
  privacy-policy template) — repo assets for the human release steps,
  nothing in-game.

### HUMAN 5-MINUTE CHECK
1. Restore any district to FULL (repair it with cable/fuse/transistor at
   its power switch). Watch the toast area (top-left): you should see
   **one** notification naming the district, in your current language —
   not two, not an English "District restored!".
2. Reach `substation`, find the cable-box puzzle, solve it. The reward
   toast ("+200 coins") should be in your current language.
3. Settings → Accessibility → toggle **Reduce Screen Shake** on. Take a
   hit from an enemy — the camera should not shake. Toggle it off, take
   another hit — the shake is back. Switch language with the panel open;
   the row label retranslates.
4. Open the Journal on the gas-station "Requisition, Countersigned" note
   (English) — the middle line reads "…needed at the center…".
5. Play for a few minutes across a district transition and a couple of
   photos — nothing should look or behave differently from before.

---

## Batch 6 (2026-09-09) — substation + power_station content merged + wired — ALL 11 DISTRICTS NOW HAVE LORE

- **`substation` (district 10) and `power_station` (district 11, the
  final district) now have readable lore**: 16 notes total covering the
  grid crew's last radio calls, a memorandum in the Architect's own
  handwriting, and the story's closing thread — the Keeper's answer to
  the player — all reachable in your current language across all 13
  supported languages.
- **This completes the lore pass for the entire game.** Every one of
  the 11 districts now has a full 8-note lore set (88 notes total),
  fully translated, fully cross-referenced.
- No gameplay-mechanic changes in this batch — content only.

### HUMAN 5-MINUTE CHECK
1. Reach `substation` (needs `industrial` at full restoration) and then
   `power_station` (needs `substation` at full restoration) — pick up
   2-3 notes in each, open the Journal, confirm titles/text show in
   your current language, not English fallback.
2. In `power_station`, find the note titled "Signal Loft — The Keeper
   Answers" — this is the first time in the game the mysterious radio
   voice actually responds instead of just repeating its loop.
3. Switch language mid-session (Settings → Language) while the Journal
   is open on one of these new notes — text should retranslate
   instantly.
4. Confirm "collect all documents" progress still counts correctly
   after picking up notes in both districts (completionist total grew
   by 16, to the game's final total).
5. General playthrough sanity check: with all 11 districts now content-
   complete, do a quick pass confirming district-to-district transitions
   (park→gas_station→police→warehouses→industrial→substation→
   power_station) still feel continuous — no missing prop zones or
   obviously empty rooms in the newer districts.

---

## Batch 5 (2026-09-09) — industrial district content merged + wired

- **`industrial` (district 9) now has readable lore**: 8 notes covering
  a factory floor frozen at the moment of the blackout, a sorting line
  that keeps running with nobody on it, and the first documents to
  bring together both major mystery threads (the Project Architect and
  the Keeper) in one place — same document-pickup/journal flow as
  every earlier district, in all 13 languages.
- **New art**: lit floor/wall tile twins for the factory interior.
- No gameplay-mechanic changes in this batch — content only.

### HUMAN 5-MINUTE CHECK
1. Reach the `industrial` district (needs BOTH `warehouses` and
   `police` at full restoration — this is the first district with two
   prerequisites), pick up 2-3 document/photo/audio-log pickups, open
   the Journal — confirm titles/text show in your current language,
   not English fallback.
2. Read the note titled "Switchgear Room — The Winding Refusal" (found
   later in the district) — it references the Project Architect
   storyline. Read the note titled "Shipping Ledger" — it references
   the Keeper. Both should be legible from this one district, which is
   new (earlier districts could only guarantee one thread or the
   other).
3. Switch language mid-session (Settings → Language) while the Journal
   is open on one of these new notes — text should retranslate
   instantly.
4. Visually confirm the factory's lit-window/floor textures actually
   change look between DARK and a later stage (compare a screenshot at
   DARK vs after restoring to STREETS/FULL).
5. Confirm "collect all documents" progress still counts correctly
   after picking up an industrial note (completionist total grew by 8).

---

## Batch 4 (2026-09-09) — warehouses district content merged + wired

- **`warehouses` (district 8) now has readable lore**: 8 notes covering
  a foreman's twenty-year logbook turning strange, a quarantined
  solid-state cage nobody can explain, and the first documents to
  reference the Act II "Project Architect" storyline directly — same
  document-pickup/journal flow as every earlier district, in all 13
  languages.
- **New/fixed art**: lit floor/wall tile twins for the warehouse
  interior, plus a small edge-seam fix on the existing dark floor tile
  (a 3-pixel border that didn't tile cleanly — invisible in most
  lighting, now corrected).
- No gameplay-mechanic changes in this batch — content only.

### HUMAN 5-MINUTE CHECK
1. Reach the `warehouses` district (hospital → warehouses per its
   `powered_by`), pick up 2-3 document/photo/audio-log pickups, open
   the Journal — confirm titles/text show in your current language,
   not English fallback.
2. Read the note titled "Storage Request — No Letterhead" (found later
   in the district) — it should reference the Project Architect
   storyline by name, since you can only reach warehouses after
   finishing hospital.
3. Switch language mid-session (Settings → Language) while the Journal
   is open on one of these new notes — text should retranslate
   instantly.
4. Visually confirm the warehouse's lit-window/floor textures actually
   change look between DARK and a later stage (compare a screenshot at
   DARK vs after restoring to STREETS/FULL); the floor should look
   seamless when tiled, no visible border lines.
5. Confirm "collect all documents" progress still counts correctly
   after picking up a warehouses note (completionist total grew by 8).

---

## Batch 3 (2026-09-09) — police district content merged + wired

- **`police` (district 7) now has readable lore**: 8 notes covering the
  station's own evacuation records, a vanished night shift, and the
  first sighting of "the Keeper's" streetlight-in-a-circle signature —
  same document-pickup/journal flow as every earlier district, in all
  13 languages.
- **New art**: lit floor/wall tile twins for the station interior, plus
  a cell-bars surface texture for the holding-cell wing.
- No gameplay-mechanic changes in this batch — content only. (Two data
  questions from the previous batch — district unlock order and a dead
  music-data field — were re-checked against this district and confirmed
  already resolved; nothing new to fix.)

### HUMAN 5-MINUTE CHECK
1. Reach the `police` district (park → police per its `powered_by`),
   pick up 2-3 document/photo/audio-log pickups, open the Journal —
   confirm titles/text show in your current language, not English
   fallback.
2. Read the note titled "Property Release, Countersigned" — its
   "Related:" line should mention the Keeper if you've been to `park`
   already (you have to have been, to reach police at all).
3. Switch language mid-session (Settings → Language) while the Journal
   is open on one of these new notes — text should retranslate
   instantly.
4. Visually confirm the station's lit-window/floor textures actually
   change look between DARK and a later stage (compare a screenshot at
   DARK vs after restoring to STREETS/FULL).
5. Confirm "collect all documents" progress still counts correctly
   after picking up a police note (completionist total grew by 8).

---

## Batch 2 (2026-09-08) — school/hospital/gas_station content merged + wired

- **3 new districts now have readable lore**: school (8 notes), hospital
  (8 notes, including the Act II "Project Architect" reveal at STREETS),
  gas_station (8 notes) — same document-pickup/journal flow as the
  earlier districts, in all 13 languages.
- **New lit tile art** for school and gas_station (floor/wall variants
  that light up as those districts restore, matching hospital/residential/
  park's existing look).
- No gameplay-mechanic changes in this batch — content + a data
  clarification (a dead, unused "music" field removed from
  `district_themes.gd`, has zero effect on what actually plays).

### HUMAN 5-MINUTE CHECK
1. Reach the `school` district (residential → school per its
   `powered_by`), pick up 2-3 document/photo/audio-log pickups, open the
   Journal — confirm titles/text show in your current language, not
   English fallback.
2. Same for `hospital` — specifically check a note found at STREETS
   stage or later mentions "Project Architect"; earlier hospital notes
   should NOT mention it by name.
3. Same for `gas_station` — one note (`Requisition, Countersigned`)
   should show a "Related: The Keeper, ..." line under its text if you've
   already been to `park`.
4. Switch language mid-session (Settings → Language) while the Journal
   is open on one of these new notes — text should retranslate instantly.
5. Visually confirm school's and gas_station's lit-window/floor textures
   actually change look between DARK and a later stage (compare a
   screenshot at DARK vs after restoring to STREETS/FULL).

---

## Batch 1 (2026-09-08) — severe/major static-audit fixes

- **Escape no longer sometimes force-quits to the main menu.** A dead
  leftover screen was eating every Escape press alongside the real pause
  menu.
- **7 previously-dead skill-tree purchases now do something**:
  Max Health, Stamina Boost, Battery Capacity, Health Regen, Light
  Radius, Damage Boost I/II, Crit Chance, Fire Rate, Reload Speed, Loot
  Luck. Before this batch, buying any of these cost real skill points
  for zero effect.
- **Skill bonuses survive Continue now.** Previously, reloading a save
  silently reset every stat-boosting skill (Max Health, Stamina Boost,
  Battery Capacity, Move Speed, Inventory Space, Light Radius) back to
  base, even though the skill still showed as "unlocked" in the menu.
- **World lighting no longer flickers/changes when a district you're not
  in gets restored.** It used to react to any district's power stage,
  not just the one you're standing in.
- **A renamed/removed inventory item can no longer occupy a permanent
  blank slot.**
- **"Collect all documents" is a real completionist goal again** instead
  of trivially done from the first two districts' lore notes.

### HUMAN 5-MINUTE CHECK
1. New Game → open the Skill Tree (default key, see Controls) → buy one
   level of **Max Health** in Survival and **Damage Boost I** in Combat.
   Confirm the skill shows "Level 1/x" and is no longer purchasable-then-
   silent (max HP number in the HUD top-left should visibly increase by
   ~20 after the Max Health buy).
2. Fire a weapon a few times after buying Damage Boost I/Fire Rate —
   shots should feel very slightly faster to fire (fire_rate) and hit
   harder (watch an enemy's HP bar drop faster than before the buy).
3. Save (pause menu → Save), then Continue from the main menu. Reopen
   the Skill Tree: the bought skills should still show as unlocked, AND
   your max HP/stamina/battery numbers should still reflect the bonus
   (not reset to the unboosted default).
4. During normal gameplay, press Escape a dozen times in a row (menu
   open/close, walking around). You should only ever see the Pause
   menu — never get bounced to the main menu unexpectedly.
5. Pick up a few battery/scrap items in the starting district; confirm
   the pickup count still looks sane (Loot Luck at level 0 should look
   identical to before this pass).
