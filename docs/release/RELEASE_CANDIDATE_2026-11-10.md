# Release candidate — 2026-11-10

This pass continues current main from `bef60fdd`; it preserves the newer darkness, architecture, restoration and offline-build work. It does not reuse the older embedded PowerShell source snapshot.

## Implemented and reviewed

- Touch controls now use measured sizes rather than overlapping fixed slots. All fourteen controls retain their action bindings, readable current-language captions/tooltips, bundled icons, minimum logical hit areas, one-handed placement and safe-area offsets. Missing action glyphs and stale English captions were fixed after actual native inspection.
- LightGrid no longer queries detached/freed lights or lets unattached registrations create phantom lit cells. The existing perception and cartography contract is preserved.
- The map opens through the actual keyboard/touch route and records only restored illumination the player observed unobstructed. Darkness and flashlight use alone chart nothing. Unknown canvas stays blank; no player, enemy, item, quest or lamp markers are rendered. District travel remains a separate screen. Only Russian and English are supported.
- Cached map and travel captions now refresh when changing Russian/English, including hidden/reopened screens, while preserving charted memory, zoom and pan. The existing localization gate reproduces both former failures and verifies the repair.
- The original menu picture and mouse parallax are preserved. A cinematic archive replaces the rejected windows, question-mark wall and visible Codex umbrella. Shared controls, bundled Cyrillic fonts and actual legacy Shop inheritance are consistent with the revised hierarchy.
- Generic notices and hover are silent. Actual pickups keep their positional sample without an added procedural blip; explicit failure feedback occurs once. Licensed human-composed menu/restored music has in-game attribution, verified sources, levels and loop seams.
- Windows proof parsing, inert attribution-URL classification, canonical font checks and the release pipeline's normal polish marker were repaired with meaningful regressions. The current-main PowerShell driver remains restartable and source/artifact checked.

## Evidence

- [UI candidates, independent votes and28 native family frames](../artifacts/release-20261110/ui/README.md)
- [Four actual lighting-based map cases and light-lifecycle regression](../artifacts/release-20261110/map/README.md)
- [Fourteen controls, native EN/RU matrix and visual RED/GREEN evidence](../artifacts/release-20261110/hud/REPORT.md)
- [Licensed music sources, mastering and native credits](../LICENSED_MUSIC_REFRESH.md)
- [Final28/28 engine gates after the map-language repair](../artifacts/release-20261110/engine/map-locale-final/verification.json)
- [Cached map-language RED/GREEN regression](../artifacts/release-20261110/map/locale-fix/README.md)
- [Decision record](../artifacts/decisions_vlog.md)

All28 final engine gates pass from the frozen source copy, including compile, signals, two-language localization, assets,655 closeout assertions and the full game suite. Native WASAPI audio passes real bus-output, peak and adaptive-layer checks. Release-judge tests pass14/14; Windows PowerShell5.1 checkout/checksum fixtures pass18/18. The one refreshed New Game+ citation restores AF5 to zero findings.

The complete static battery passes72/72. Native audio and the seeded autoplay were performed on the preceding `00bfdd1e` revision; the subsequent repair changes cached map captions only. Their historical capture identity is preserved, and the complete engine battery is rerun after that repair.

The delivered runtime source is `a2672e7736ce34c4e8e3021cdc576d3cff68bfa1`. Windows and Web were exported from that clean commit; the packaged Windows EXE initializes native rendering and exits without fatal errors after900 frames. The Windows build is unsigned. Web is built but has not been verified in a browser. Both archives include third-party notices and source identity; exact file sizes and SHA256 values are in the [build manifest](../artifacts/release-20261110/engine/map-locale-final/build-manifest.json). Eight new1920×1080 [source-stamped frames](../artifacts/release-20261110/engine/map-locale-final/fresh-frames.json) document this commit's staged states without claiming store-creative acceptance.

An actual seeded autoplay reaches WIN, with2deaths and14 automatic nudge rescues. This proves the assisted progression path reaches the ending; it does not certify clean navigation or human traversal. Native UI fixtures and staged ending screenshots are identified as such. Known retained-resource diagnostics remain in the raw output rather than being presented as a clean teardown.

## Run the current source

Copy `tools/release/Finish-IgraRelease.ps1` anywhere and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Finish-IgraRelease.ps1
```

Repeat to resume the pinned revision; add `-Update` to take current main. The driver checks the game before Windows/Web export. Android additionally needs the existing release signing environment, SDK and JDK; it does not generate a replacement signing identity or upload a store release.

## Remaining release acceptance

This is a verified engineering candidate, not a claim that every release criterion is complete. The map drawing is deliberately limited to coarse observed architectural cells. The new world-material candidates remain rejected for distant facade repetition and weak Low-tier detail; no rejected shader rollout or concealment through post-processing is shipped. Whole-world photographic parity with the menu reference remains unfinished.

Human listening and physical-phone touch/DPI/performance acceptance remain unverified. ADB reports no attached devices. Headless OGG resource-retention warnings remain recorded; no clean teardown/leak-fix claim is made. Existing Android release signing credentials are unavailable in this checkout, so the previous signed AAB does not certify this newer source. Cloudflare deployment and the unidentified Dots connection are unverified; only the locally tested Cloudflare tooling is supplied. No store submission is made.
