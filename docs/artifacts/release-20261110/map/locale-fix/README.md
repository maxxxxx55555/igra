# Cached map localization repair — 2026-11-10

**Confirmed RED → GREEN.** The existing i18n gate opens the real cached `UIManager` map/travel routes. Switching an already-open architectural map from English to Russian left its seven captions in English; closing the travel list, changing language and reopening left its cached Close button in English. RED exited 1 with two failures in 12.0 seconds: [raw output](red.out).

The architectural map now binds its existing title, blank hint and five buttons to `LocalizationManager.language_changed`. District travel refreshes its cached Close caption and existing title/list route on the same signal. Controls are retained in place; charted memory, drawing rules, zoom and pan are untouched. The regression uses nonempty saved chart data and verifies that the language switch preserves it together with a nondefault zoom/pan.

GREEN exited 0 in 7.6 seconds: dictionary/key/placeholder checks and four cached-route/state assertions pass, including English→Russian captions, hidden/reopened travel Close and switching back to English. No engine error was reported: [raw output](green.out). [evidence.json](evidence.json) records exact outcomes and all three final source/QA raw hashes plus Git blob digests. Root runs the final complete gates/build after this source freeze.

**Earlier map visual evidence is historical.** Its four screenshots, captured-source raw hashes, stored old source snapshots and Git digests remain unchanged; they were produced before this caption-only repair. This headless behavioral regression does not claim a new native Russian screenshot or physical-device test.
