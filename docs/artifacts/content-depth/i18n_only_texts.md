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
| `DOC_BLACKOUT_NEWS_TEXT` | “EON announces: the outage will last no more than a day. Residents are asked to remain calm...” |
| `DOC_BOSS_SUIT_TEXT` | “Surname blacked out. Position: director. Special notes: never once seen in daylight.” |
| `DOC_BOSS_SUIT_TITLE` | EON Director's Personnel File |
| `DOC_CABLE_MATH_TEXT` | “Total reserve capacity: 0. Extent of damage: the entire city.” |
| `DOC_CABLE_MATH_TITLE` | Power Grid Calculation (Illegible) |
| `DOC_CHILDREN_COUNTING_TEXT` | “One — the light went out. Two — it's here with us. Three — don't look. Four — don't be the seeker.” |
| `DOC_CHILDREN_COUNTING_TITLE` | Schoolyard Counting Rhyme (Basement Version) |
| `DOC_CORE_STATION_TEXT` | “Central station: output 800 MW, reserve of 3 generators. Special conditions: DO NOT START AFTER 23:00.” |
| `DOC_CORE_STATION_TITLE` | Central Station Technical Passport |
| `DOC_ENGINEER_WARNING_TEXT` | “To all crews: DO NOT OPEN the substations without an order. What we found inside is not what we expected.” |
| `DOC_ENGINEER_WARNING_TITLE` | Chief Engineer's Warning |
| `DOC_EON_CONTRACT_TEXT` | “Clause 13: the city grants EON the right to use the power grid for research purposes.” |
| `DOC_EVACUATION_ORDER_TEXT` | “Second list: 47 people. Assembly point: the schoolyard, 04:00.” |
| `DOC_EVACUATION_ORDER_TITLE` | Evacuation Order: List No. 2 |
| `DOC_FACTORY_LOG_TEXT` | “22:00 — strange hum from the generator. 23:15 — the light in workshop B is flickering.” |
| `DOC_FINAL_LIGHT_TEXT` | “My father lit the streetlights, my grandfather lit the streetlights. I am the last. When I left the city, the light went out.” |
| `DOC_FINAL_LIGHT_TITLE` | The Lamplighter's Last Will |
| `DOC_FIRST_DEATH_TEXT` | “A city without light is like a house without doors. I saw her come out of the wall.” |
| `DOC_FIRST_DEATH_TITLE` | Note from a Dead Man's Pocket |
| `DOC_FOREMAN_NOTE_TEXT` | “The conveyor has started to think it's the foreman. No, I haven't lost my mind. I've worked here for 20 years.” |
| `DOC_GENERATOR_MANUAL_TEXT` | “Step 1: Make sure the room is ventilated. Step 2: Make sure there are no wires nearby.” |
| `DOC_GENERATOR_MANUAL_TITLE` | GT-3000 Generator Manual |
| `DOC_HOSPITAL_NOTE_TEXT` | “Patient brought in from substation Zh-3. Does not speak, does not eat, stares at the lamp.” |
| `DOC_HYMN_TEXT` | “Holy light that burns in the night, protect us from those who live in the wires. Amen.” |
| `DOC_HYMN_TITLE` | The Lamplighters' Prayer |
| `DOC_KING_NOTE_TEXT` | “You made it to the center. So I was right about you. Put out the light at the station — not for yourself.” |
| `DOC_LAST_WILL_TEXT` | “Whoever finds this note: do not look for my body. I went into substation Zh-3 with a lamp in my hands.” |
| `DOC_MACHINE_DIARY_TEXT` | “Day 1: I am a conveyor. Day 3: I remember the hands that assembled me. Day 7: I assemble hands.” |
| `DOC_MACHINE_DIARY_TITLE` | The Machine's Diary (Unsigned) |
| `DOC_MURDER_LETTERS_TEXT` | “Dear neighbor! I switch off your light at 23:00, because it disturbs my peace.” |
| `DOC_OLD_WOMAN_TEXT` | “Sonny, if you're reading this, you're alive, and that's what matters. Granny Manya says: the light in this city isn't electricity.” |
| `DOC_OLD_WOMAN_TITLE` | Letter from the Old Woman at No. 24 |
| `DOC_PROTOCOL_DAWN_TEXT` | Secret EON order No. 7: in case of irreversible failure of the power grid, launch Protocol DAWN. |
| `DOC_RADIO_DIARY_01_TEXT` | “Friday. The grid died at 03:14. The radio still picks up static from the north.” |
| `DOC_RADIO_DIARY_01_TITLE` | Radio Operator's Diary: Day 1 |
| `DOC_RADIO_DIARY_02_TEXT` | “The Morse from the north has become clearer. They are transmitting: ‘LIGHT-LIGHT-LIGHT-NOT-LIGHT-LIGHT’.” |
| `DOC_RADIO_DIARY_02_TITLE` | Radio Operator's Diary: Day 12 |
| `DOC_RELAY_NOTES_TEXT` | “Relay 4-7 trips every 47 minutes, exactly. It started the very day of the outage.” |
| `DOC_RESEARCHER_FINAL_TEXT` | “Experiment ‘Conductor’: we connected the substations to the anomaly. It responds to power.” |
| `DOC_RESEARCHER_FINAL_TITLE` | EON Researcher's Final Report |
| `DOC_SCAVENGER_TEXT` | “Haul for the night: batteries — 14, ammo — 3 boxes, food — not food, but what she left behind.” |
| `DOC_SCHOOL_INCIDENT_TEXT` | “Teacher on duty: March 15, classes cancelled. All 300 students were in the basement.” |
| `DOC_SCHOOL_INCIDENT_TITLE` | School Logbook: Last Entry |
| `DOC_STATION_LOG_FINAL_TEXT` | “23:59 — Power: 0%. Anomaly: 100%. The station: no longer a station. Me: no longer me.” |
| `DOC_STREETLIGHT_MANIFESTO_TEXT` | “As long as a single streetlight burns, the city lives. I repaired them for forty years. Now I repair them the other way round.” |
| `DOC_STREETLIGHT_MANIFESTO_TITLE` | The Lamplighter's Manifesto |
| `DOC_STRIKE_TEXT` | “Workers of Factory No. 9, March 12: we demand the night shift be abolished! At night the machines run by themselves.” |
| `DOC_SUBSTATION_GUARD_TEXT` | “Shift 12, security: the facility cannot be entered, the door is welded shut.” |
| `DOC_SURVIVOR_TIPS_TEXT` | “1. Don't run — running attracts them. 2. Light — turn it on for only 10 seconds, then switch it off.” |
| `DOC_SURVIVOR_TIPS_TITLE` | Survivor's Notes: How to Walk at Night |
| `DOC_VOICE_IN_WIRES_TEXT` | “— Do you hear it? The hum in the wires. It isn't a hum. It's speech. Slow speech, carried on current.” |
| `DOC_VOICE_IN_WIRES_TITLE` | Dictaphone Recording (Transcript) |
| `Dyslexia Font (OpenDyslexic)` | Dyslexia Font (OpenDyslexic) |
| `END_NONE_HINT` | No ending conditions were met. |
| `FIRST_RESTORE` | First district restored! |
| `HINT_INVENTORY` | Tab — inventory. Watch your weight |
| `ITEM_BLUEPRINT_ENHANCED_BATTERY` | Blueprint: enhanced battery |
| `ITEM_BLUEPRINT_PORTABLE_WORKBENCH` | Blueprint: portable bench |
| `Level: %d\nPlaytime: %s\n%s` | Level: %d\nPlaytime: %s\n%s |
| `MONSTER_DESC_BOSS` | The source of the power plant disaster. Light does not harm it. |
| `MONSTER_DESC_BRUTE` | A heavy charger that winds up a slam and follows through with a lunge, then needs to recover. |
| `MONSTER_DESC_BURNER` | Spits a burning payload from range and flees in panic when caught in the light. |
| `MONSTER_DESC_CRAWLER` | A darting creature. It lunges at any noise, so do not run near it. |
| `MONSTER_DESC_CRAWLER_ARACHNOPHOBIA` | A darting creature. It lunges at any noise, so do not run near it. |
| `MONSTER_DESC_DESTROYER` | A slow bruiser. At point-blank range it knocks out your flashlight, and in the dark you are defenseless. |
| `MONSTER_DESC_HOUND` | A fast pack hunter that howls for allies the instant it spots you. |
| `MONSTER_DESC_HUNTER` | Follows your trail. When it loses sight of you, it combs the spot of the last noise for a long time. |
| `MONSTER_DESC_ROTTER` | A slow, omnidirectional tank that poisons on contact and ignores light entirely. |
| `MONSTER_DESC_SHADOW` | A clot of darkness. It cannot stand light: in a flashlight beam it writhes and dies. |
| `MONSTER_DESC_SHARPSHOOTER` | A ranged sentry that fires from cover and retreats if you close the distance. |
| `MONSTER_DESC_TVAR` | A hulking mini-boss that slows under light and staggers only after a landed combo. |
| `MONSTER_DESC_WATCHER` | A motionless sentry with a narrow field of view. Once it spots you, it raises the alarm. |
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
| `SHOP_ITEM_UPGRADE_FLASHLIGHT_BRIGHTNESS` | Flashlight brightness +1 |
| `Server created! Waiting for players...` | Server created! Waiting for players... |
| `TUT_FIND_FLASHLIGHT` | Find the flashlight. Press F to switch it on. |
| `TUT_FIRST_SHADOW` | A Shadow is close. Hold it in the beam. |
| `TUT_GENERATOR_STEP1` | Connect the cables in the right order. |
| `TUT_LIGHT_SHIELD` | Light is your shield. Monsters fear the beam. |
| `TUT_TO_GARAGE` | Head to the garage. The generator is there. |
| `menu_subtitle` | A survivor in an eternal night. Bring the light back to the city. |
| `tip1` | Keep the flashlight on - enemies fear light. |
| `tip2` | Reloading takes 1.5 seconds. |
| `tip3` | Use cover when HP is low. |
| `tutorial_done` | Tutorial complete. Good luck! |

Total: 184 keys.

Verified: none of these keys appears in any `.gd`, `.tscn` or
`.tres` under `scripts/`, `scenes/` or `components/`, and none is
backed by a `content/**` entry. They are dead or unadopted strings.
