# Player-visible changes

Running log, newest batch first. Written for the owner doing manual
in-game verification — a static-only pass can't play the game itself.

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
