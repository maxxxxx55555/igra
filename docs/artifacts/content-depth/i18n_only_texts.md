# TASK 3 — texts living ONLY in i18n (CODE-sync table)

Keys whose prose exists in `data/i18n/*.json` but is backed by no
`content/**` entry and referenced by no script/scene. For these the
locale file is the only source of truth, which inverts the repo rule
that `content/**` is the source of truth for authored content.
**Locales were not touched.** Proposed `en` = current value verbatim;
CODE decides whether to adopt each into a content file or wire it.

| key | proposed `en` |
|---|---|
| `CAPTION_GALLERY_BABKA_LAMP` | Babka Manya's lamp. "The light in this city is not electricity." |
| `CAPTION_GALLERY_GAS_STATION` | Fuel, fumes, and one fluorescent that refuses to die. |
| `CAPTION_GALLERY_HOSPITAL` | The generators held longest here. So did the nurses. |
| `CAPTION_GALLERY_INDUSTRIAL` | The presses stopped mid-stroke. The dark likes the echo in here. |
| `CAPTION_GALLERY_LAST_STREETLIGHT` | The last streetlight. While it burns, the city lives. |
| `CAPTION_GALLERY_NIGHT_ZERO` | Night Zero. 03:14. The city exhaled, and the dark inhaled. |
| `CAPTION_GALLERY_PARK` | The lamps here drink the fog. Pretty. Hungry. Both. |
| `CAPTION_GALLERY_POLICE` | The holding cells are empty. The radio isn't. Don't ask. |
| `CAPTION_GALLERY_POWER_STATION` | The center. My forty years end here — one way or another. |
| `CAPTION_GALLERY_RESIDENTIAL` | A thousand windows. I count the lit ones every night. The count grows. |
| `CAPTION_GALLERY_SCHOOL` | Somebody chalked a sun on the blackboard. It outlasted the grid. |
| `CAPTION_GALLERY_SUBSTATION` | Marat walked in here and never walked out. Mind the hum. |
| `CAPTION_GALLERY_SUBURBS` | Where the lights went out first, and where they'll come back first. |
| `CAPTION_GALLERY_THE_ARCHITECT` | It built its nest in the dead grid. Tonight we evict it. |
| `CAPTION_GALLERY_THE_KEEPER` | Forty years of work orders. This face kept every lamp logged by hand. |
| `CAPTION_GALLERY_WAREHOUSES` | Crates of lamps nobody installed. I installed them. You're welcome. |
| `CAPTION_MOMENT_DOC_BLACKOUT_NEWS` | The last paper says one day. It has been years. Somebody tore the date out — hope or mercy. |
| `CAPTION_MOMENT_DOC_FINAL_LIGHT` | "While one lamp burns, the city lives." I wrote that. I still believe it. |
| `CAPTION_MOMENT_DOC_FIRST_DEATH` | A dead man's note: "Light is the only prayer." He was right. He is still right. |
| `CAPTION_MOMENT_DOC_MANIFESTO` | Found my own manifesto by the last lamp. Younger handwriting. Same promise. |
| `CAPTION_MOMENT_DOC_PROTOCOL_DAWN` | EON's Protocol Dawn: lock the grid, save the staff. They locked it. Nobody saved anybody. |
| `CAPTION_MOMENT_DOC_VOICE_IN_WIRES` | Something talks on the wires at night. I log the words. I do not answer. |
| `CAPTION_MOMENT_ENDING_DARKNESS` | Last night. I blew the lamps out myself. Forgive me. It was the only way to starve it. |
| `CAPTION_MOMENT_ENDING_LIGHT` | Last night. The grid held. Forty years of work orders — paid in full. |
| `CAPTION_MOMENT_FIRST_LIGHT` | Night 1. One lamp. Mine. The street remembered what morning was. |
| `CAPTION_MOMENT_NG_PLUS` | Night 1, again. The city reset; I didn't. The log continues. It always continues. |
| `CAPTION_MOMENT_OVERLOAD` | Night 63. Pack's too heavy; back's too old. Still carried it home. |
| `CAPTION_MOMENT_PHOTOGRAPHER` | Night 40. Ten frames kept. If the grid forgets us, the film won't. |
| `DAILY_DARK_05_FLAVOR` | Five segments, flashlight OFF. Trust the lamps. |
| `DAILY_DARK_10_FLAVOR` | Ten segments in lamp-light only. Walk like the Keeper. |
| `DAILY_KILL_01_FLAVOR` | One shadow. Every long night starts with one. |
| `DAILY_KILL_02_FLAVOR` | Two shadows. Warm up the flashlight. |
| `DAILY_KILL_03_FLAVOR` | Three of them. Enough to remind the street who walks it. |
| `DAILY_KILL_05_FLAVOR` | Five. They come for the light; meet them before it. |
| `DAILY_KILL_08_FLAVOR` | Eight. Count them the way you count fuses — carefully. |
| `DAILY_KILL_10_FLAVOR` | Ten tonight. The dark can spare them. |
| `DAILY_KILL_12_FLAVOR` | Twelve. A dozen reasons the lamps stay lit. |
| `DAILY_KILL_15_FLAVOR` | Fifteen. Long night. Keep the lamp behind you. |
| `DAILY_KILL_20_FLAVOR` | Twenty. Whatever is out there is running out of sons. |
| `DAILY_KILL_25_FLAVOR` | Twenty-five. Marat's whole shift quota in one night. |
| `DAILY_KILL_40_FLAVOR` | Forty. One for every year the Keeper kept the lamps. |
| `DAILY_PHOTO_01_FLAVOR` | One subject. Frame something worth remembering. |
| `DAILY_PHOTO_03_FLAVOR` | Three subjects. The city's portrait, one frame at a time. |
| `DAILY_PHOTO_05_FLAVOR` | Five subjects. A gallery of the almost-lost. |
| `DAILY_PLAY_03_FLAVOR` | Three minutes. Long enough to check the fuses. |
| `DAILY_PLAY_05_FLAVOR` | Five minutes out there. The lamps notice. |
| `DAILY_PLAY_08_FLAVOR` | Eight minutes. Walk the line, listen to the hum. |
| `DAILY_PLAY_120_FLAVOR` | Two hours. A full watch. Log it with pride. |
| `DAILY_PLAY_12_FLAVOR` | Twelve minutes. The city is quieter when you are in it. |
| `DAILY_PLAY_15_FLAVOR` | Fifteen minutes on the wire. Steady work. |
| `DAILY_PLAY_20_FLAVOR` | Twenty minutes. That is a shift, Keeper. |
| `DAILY_PLAY_30_FLAVOR` | Thirty minutes. Half an hour against the dark. |
| `DAILY_PLAY_45_FLAVOR` | Forty-five. The lamps know your footsteps by now. |
| `DAILY_PLAY_60_FLAVOR` | Sixty minutes. A full hour. The Keeper nods. |
| `DAILY_PLAY_90_FLAVOR` | Ninety minutes. Overtime in the light brigade. |
| `DAILY_RESTORE_01_FLAVOR` | One district back on the grid. Start somewhere. |
| `DAILY_RESTORE_02_FLAVOR` | Two. The map stops being a list of losses. |
| `DAILY_RESTORE_03_FLAVOR` | Three districts. The wire remembers the shape of the city. |
| `DAILY_RESTORE_04_FLAVOR` | Four. Power flows the way water used to. |
| `DAILY_RESTORE_05_FLAVOR` | Five. Half the city can see its own hands. |
| `DAILY_RESTORE_06_FLAVOR` | Six districts lit. Keep going; the rest are waiting. |
| `DAILY_RESTORE_07_FLAVOR` | Seven districts. The blackout is losing. |
| `DAILY_RESTORE_08_FLAVOR` | Eight districts. Hold the line, lamp by lamp. |
| `DAILY_RESTORE_09_FLAVOR` | Nine districts. Almost the whole grid humming. |
| `DAILY_RESTORE_10_FLAVOR` | Ten districts. One short of a miracle. |
| `DAILY_RESTORE_11_FLAVOR` | Eleven districts. The whole city. All of it. FULL. |
| `DAILY_SECRET_01_FLAVOR` | One secret. Start where the wiring hums. |
| `DAILY_SECRET_02_FLAVOR` | Two things the city hid. It hides badly. |
| `DAILY_SECRET_03_FLAVOR` | Three. Look where nobody bothered to look twice. |
| `DAILY_SECRET_04_FLAVOR` | Four secrets. Check behind the fuse boxes. |
| `DAILY_SECRET_05_FLAVOR` | Five. Every street keeps something in its pockets. |
| `DAILY_SECRET_06_FLAVOR` | Six secrets. The quiet corners pay out. |
| `DAILY_SECRET_08_FLAVOR` | Eight. The Keeper wrote things down. Find them. |
| `DAILY_SECRET_10_FLAVOR` | Ten secrets. A full page in the Keeper's log. |
| `DAILY_SECRET_12_FLAVOR` | Twelve. You are reading someone else's life now. |
| `DAILY_SECRET_16_FLAVOR` | Sixteen. By now the city is telling you the truth. |
| `DAILY_SECRET_24_FLAVOR` | Twenty-four. Every hidden thing in one night. Legend work. |
| `DAILY_STREETS_01_FLAVOR` | One lamp. It is how every night starts. |
| `DAILY_STREETS_02_FLAVOR` | Two lamps. A direction, not yet a road. |
| `DAILY_STREETS_03_FLAVOR` | Three lamps. Someone could find their way home. |
| `DAILY_STREETS_04_FLAVOR` | Four. The dark has to step back to make room. |
| `DAILY_STREETS_05_FLAVOR` | Five streets. A fistful of dawn. |
| `DAILY_STREETS_06_FLAVOR` | Six lamps lit. The street begins to look like a street. |
| `DAILY_STREETS_07_FLAVOR` | Seven streets. Lucky current. |
| `DAILY_STREETS_08_FLAVOR` | Eight. Stand at one end and you can see the other. |
| `DAILY_STREETS_09_FLAVOR` | Nine streets. The grid hums your name. |
| `DAILY_STREETS_12_FLAVOR` | Twelve streets. A whole district's worth of dawn. |
| `DAILY_STREETS_16_FLAVOR` | Sixteen streets. Light the city like it's Night Zero in reverse. |
| `DISTRICT_2_TOAST` | District 2 restored! The city breathes again. |
| `Dyslexia Font (OpenDyslexic)` | Dyslexia Font (OpenDyslexic) |
| `FIRST_RESTORE` | First district restored! |
| `Level: %d\nPlaytime: %s\n%s` | Level: %d\nPlaytime: %s\n%s |
| `NGP_BLACKOUT_PLUS_DESC` | One extra district starts DARK. No head start, no mercy. |
| `NGP_GHOST_DESC` | Crawlers ignore you. Achievements disabled. Unseen, unrecorded. |
| `NGP_KEEPERS_PACT_DESC` | No hints. Lore insight doubled. He never explained either. |
| `NGP_LONG_NIGHT_DESC` | Battery yields 20% less light. The dark is patient; your cells are not. |
| `NGP_SPRINT_DESC` | Night cycle 15% shorter, rewards +50%. Run the light home. |
| `NGP_WHISPER_DESC` | Hunters hear 30% less, but loot yields 10% less. Tread soft, carry little. |
| `NG_PLUS_ACTIVATED` | New Game+ activated! Difficulty increased. |
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

Total: 113 keys.

Verified: none of these keys appears in any `.gd`, `.tscn` or
`.tres` under `scripts/`, `scenes/` or `components/`, and none is
backed by a `content/**` entry. They are dead or unadopted strings.
