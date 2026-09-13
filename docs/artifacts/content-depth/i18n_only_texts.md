# TASK 3 — texts living ONLY in i18n (CODE-sync table)

Keys whose prose exists in `data/i18n/*.json` but is backed by no
`content/**` entry and referenced by no script/scene. For these the
locale file is the only source of truth, which inverts the repo rule
that `content/**` is the source of truth for authored content.
**Locales were not touched.** Proposed `en` = current value verbatim;
CODE decides whether to adopt each into a content file or wire it.

| key | proposed `en` |
|---|---|
| `DISTRICT_2_TOAST` | District 2 restored! The city breathes again. |
| `Dyslexia Font (OpenDyslexic)` | Dyslexia Font (OpenDyslexic) |
| `Level: %d\nPlaytime: %s\n%s` | Level: %d\nPlaytime: %s\n%s |
| `SCR_PRODERZHALIS_S_DOKUMENTOV_NAYDENO_D_VOSSTANO` | Survived %s / Documents found %d / Districts restored %d/11 |
| `SCR_PROGRESS_DOSTIZHENIY_28_56_50` | ACHIEVEMENT PROGRESS 28/56 (50%) |
| `SCR_VKLYUCHITE_PERVYY_FONAR` | Switch on the first streetlight |
| `SCR_VOSSTANOVITE_100_FONAREY` | Restore 100 streetlights |
| `Server created! Waiting for players...` | Server created! Waiting for players... |
| `TUT_FIND_FLASHLIGHT` | Find the flashlight. Press F to switch it on. |
| `TUT_FIRST_SHADOW` | A Shadow is close. Hold it in the beam. |
| `TUT_GENERATOR_STEP1` | Connect the cables in the right order. |
| `TUT_TO_GARAGE` | Head to the garage. The generator is there. |
| `menu_subtitle` | A survivor in an eternal night. Bring the light back to the city. |
| `tip1` | Keep the flashlight on - enemies fear light. |
| `tip2` | Reloading takes 1.5 seconds. |
| `tip3` | Use cover when HP is low. |
| `tutorial_done` | Tutorial complete. Good luck! |

Total: 17 keys.

Verified: none of these keys appears in any `.gd`, `.tscn` or
`.tres` under `scripts/`, `scenes/` or `components/`, and none is
backed by a `content/**` entry. They are dead or unadopted strings.
