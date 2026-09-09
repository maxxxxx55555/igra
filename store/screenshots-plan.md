# Play Store screenshots — capture plan (8 shots)

Owner: CONTENT/store agent. These are capture instructions for the human owner running a real
build (Android or PC export). Each row names the **exact scene**, the **game state to reach**,
the **framing**, and the **settings/language** to use. Zone ids are real anchors from
`content/districts/*/prop_manifest.md` and `lore_notes.json` location hints. Every shot must
read at a glance: permanent night, cold blue-black, ONE warm source of light (palette
`docs/STYLE_GUIDE.md`). Never show the death screen, HUD clutter, or the player mid-attack.

Capture settings for all shots: **Language = English** (set in Options → Language) unless a
Russian variant is explicitly wanted for the RU listing; **Graphics = High**; **Resolution =
device native**; turn the **HUD off** for the four clean vista shots (1, 2, 5, 7) so the light
does the talking; on Android, hold the device in **landscape**. Google Play screenshots are
16:9-friendly; keep the key action in the safe central band (Play crops top/bottom). After each
phone shot, a 7″-tablet 16:9 variant can be cropped from the same run.

| # | Selling point | Scene to capture (district · zone) | Reach this state | Framing / mood | Settings |
|---|---|---|---|---|---|
| 1 | The hook — light vs. the dark | suburbs · `z_exit_north` / `z_maple_row` — the last lit streetlight before the exit | Restore suburbs to FULL, return to the north exit | Wide reverse: warm streetlight cones recede toward camera down Maple Row; beyond the exit the road is black. Player off-screen. | EN · HUD off |
| 2 | The map is one city — a district boundary | residential east boundary · `z_exit_east` (barricade toward park) | residential restored FULL; park still DARK | Stand at the barricade facing the park: lit residential block behind you, black trees/pond ahead, one brass lamp marking the edge. | EN · HUD off |
| 3 | Stealth horror | residential courtyard · `z_courtyard_play` (playground + swing, chalk lamp) | residential DARK or PARTIAL, flashlight on | Player lower-right with the flashlight pool on the chalk-sun; a tall shadow waits just outside the light at the far edge. Tension, not action. | EN · HUD on (flashlight) |
| 4 | The voice / keeper lore | park · `z_keeper_shed` (shortwave on the bench) | park DARK onward (Keeper manifesto readable) | Tight on the keeper's shed work bench: one brass work lamp, the shortwave, scattered papers — the "go to the power station" radio voice, no enemies. | EN · HUD off |
| 5 | Restored world, nobody home | gas_station forecourt · `z_pump_island` / `z_forecourt` | gas_station restored FULL | Canopy sodium pools on the empty wet forecourt, dead pump displays, thin fog, the queue road dark beyond. Working station, no people. | EN · HUD off |
| 6 | The mystery inside | industrial · `z_workshop_b` (bench by the sorting line) | industrial DARK onward | A single overhead burning full and warm over an empty bench; the dark plant around it. Unsettling, silent, no operator. | EN · HUD off |
| 7 | The ending — the last streetlight | power_station gate · `z_station_gate` + `z_cooling_towers` | power_station restored FULL (final district) | Wide from the cooling-tower gantry: towers lit from below, the gate lamp burning at the foot with the hand truck and the bowl of food (note 08). Hopeful close. | EN · HUD off |
| 8 | Scope & localization | In-game Map / Progress screen | Most districts restored | The 11-district chain map, most rings lit and one dark — proves scale and continuity. A companion crop may show Options → Language listing the 13 locales. | EN (+ optional RU copy) |

Notes for the owner
- Shots 1/2/5/7 are the "money" light-vs-dark frames — if any one must be perfect, it is #1.
- Keep a second pass in **Russian** (language = Русский) for shot 8 and optionally #1 so the RU
  listing has local screenshots; Play prefers each locale's own-language screenshots.
- Frame at native res; avoid resizing up. Do not add text/arrows over the image — Play applies
  its own overlay.
- If a zone is not yet reachable in the build, fall back to the nearest lit streetlight or the
  district's main restored thoroughfare and keep the same single-light framing.
