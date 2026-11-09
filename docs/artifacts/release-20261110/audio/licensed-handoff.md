# Licensed music evidence — 2026-11-10

The selected human-composed recordings are Hymn (menu) and Moonlight (eight restored calm themes), by Scott Buckley under CC-BY 4.0. All eleven dark signatures, three distinct lit beds, combat/boss tracks, adaptive layers and runtime timing remain unchanged. Existing AI music disclosure remains because other generated tracks still ship.

| Master | Duration | Integrated | True peak | Decoded wrap step |
| --- | --- | --- | --- | --- |
| Hymn | 119.291 s | -18.0 LUFS | -2.2 dBTP | 0.00002821 |
| Moonlight | 252.334 s | -18.0 LUFS | -2.0 dBTP | 0.00000223 |

Both complete official MP3 sources were size/hash verified; both final mono 44.1 kHz Vorbis files decode completely, and both wrap steps pass the existing 0.037 limit. The existing recipe performs a two-second circular tail/head overlap, 3 ms edge guards and level matching; no pitch or tempo stretch. Exact source/master hashes, URLs, sizes and recipe are in [mastering-manifest.json](mastering-manifest.json) and [ASSET_LICENSES](../../../ASSET_LICENSES.md). Reproduction: [master_licensed_music.py](../../../../tools/qa_sim/master_licensed_music.py).

Behavior RED produced four expected failures with the old music bindings/credits. Final isolated headless GREEN passed in 7.8 s with `DONE fails=0`: actual playing Hymn/Moonlight streams on Music, restored-to-dark fallback, first-input silence, artist/title/source/license/change notices in both locale flows, action-specific feedback and victory/menu/new-run handoff. Targeted QA import passed. [Source/validation hashes](source-sha-manifest.json) preserve the exact inputs and external log digests without committing raw logs.

Corrected native credits probe passed in 8.7 s. Each locale/tier preserves a focused Back button inside the viewport with 48 px logical minimum height and an attribution scroll that reaches its 19 px end. Four actual frames were inspected:

- [English High, 1920x1080](credits_en_tier2.png) · [Russian High, 1920x1080](credits_ru_tier2.png).
- [English Low, 1280x720](credits_en_tier0.png) · [Russian Low, 1280x720](credits_ru_tier0.png).

Artist/title/source/license text is readable; the Changes notice lies below the initial scroll cut and is reachable at the verified end. A first probe rendered under UIManager's menu CanvasLayer and was discarded; these are the corrected actual credits-scene frames. The probe tested focus, bounds and scroll position; it did not simulate every mouse/touch interaction or certify phone readability.

Remaining limits: the final short headless run reports 60 retained ObjectDB instances and 28 resources at process teardown. No clean-teardown or leak-fix claim is made. A real bus-output check is separate from these headless player-route assertions. Human listening remains pending: model audio input was unavailable, so the human provenance, published piano/strings descriptions and numerical checks are not subjective pleasantness approval. No additional candidate or replacement is silently declared accepted.

Official sources: [Hymn](https://www.scottbuckley.com.au/library/hymn/), [Moonlight](https://www.scottbuckley.com.au/library/moonlight/), [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/), verified 2026-11-10. Attribution and the change notice are in-game and in the [store/distribution credit block](../../../store/HUMAN_CHECKLIST.md).
