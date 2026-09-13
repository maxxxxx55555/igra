# docs/artifacts/ui-audio/license_check.md — CC0 license URL re-check (2026-09-13)

## Canonical CC0 deed (fetched via fetch_page)

URL: `https://creativecommons.org/publicdomain/zero/1.0/`
Title: `Deed - CC0 1.0 Universal - Creative Commons`
Fetched 2026-09-13, snippet:

> **No Copyright**
> 1. The person who associated a work with this deed has **dedicated** the work to the public domain by waiving all of his or her rights to the work worldwide under copyright law...
> 2. You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission. See **Other Information** below.

Legal code URL linked: `https://creativecommons.org/publicdomain/zero/1.0/legalcode.en` (same as `https://creativecommons.org/publicdomain/zero/1.0/legalcode`).

Status: **PASS** — deed explicitly allows commercial use without permission/attribution.

## Local LICENSE-AUDIO files (after git clone)

### /tmp/uisfx/LICENSE-AUDIO
```
UI SFX audio assets are dedicated to the public domain under the Creative
Commons CC0 1.0 Universal Public Domain Dedication.

To the extent possible under law, Yuki Capital has waived all copyright and
related or neighboring rights to the procedurally generated audio files in
`packages/uisfx/sounds`.

You may copy, modify, distribute, and use these files, including for commercial
purposes, without asking permission. Attribution is appreciated but not
required.

Legal code: https://creativecommons.org/publicdomain/zero/1.0/legalcode
SPDX identifier: CC0-1.0
```

### /tmp/uisfx/packages/uisfx/LICENSE-AUDIO
```
The audio files under `sounds/` are dedicated to the public domain under the
Creative Commons CC0 1.0 Universal Public Domain Dedication.

You may copy, modify, distribute, and use these files, including commercially,
without asking permission. Attribution is appreciated but not required.

Legal code: https://creativecommons.org/publicdomain/zero/1.0/legalcode
SPDX identifier: CC0-1.0
```

### /tmp/kenney_ui/addons/kenney_ui_audio/LICENSE.txt
```
UI SFX Set
by  Kenney Vleugels (Kenney.nl)
------------------------------
License (Creative Commons Zero, CC0)
http://creativecommons.org/publicdomain/zero/1.0/
You may use these assets in personal and commercial projects.
Credit (Kenney or www.kenney.nl) would be nice but is not mandatory.
...
Follow on Twitter for updates:
@KenneyNL
```

All three local license files contain `CC0` and point to `https://creativecommons.org/publicdomain/zero/1.0/` (or `/legalcode`).

## Kenney web page (fetch_page)

URL: `https://kenney.nl/assets/ui-audio`
Fetched table:

| Tags | button switch click |
| Category | Audio |
| Files | 50× |
| License | [Creative Commons CC0](https://creativecommons.org/publicdomain/zero/1.0/) |

URL: `https://kenney.nl/assets/music-jingles` — same CC0 line, 85×.

Status: **PASS** — both Kenney packs are CC0 1.0 Universal, deed URL live.

## uisfx manifest license field (after clone)

`packages/uisfx/manifest.json` excerpt:

```json
"license": { "code": "MIT", "audio": "CC0-1.0" },
"source": "Deterministic UI SFX synthesis recipes"
```

Audio license explicitly `CC0-1.0`.

## Attribution requirement

All 7 files: **none required (CC0)** — “Attribution is appreciated but not required” (uisfx) and “Credit would be nice but is not mandatory” (Kenney). Ledger correctly lists attribution as “none required (CC0)” with optional credit line for provenance, not a legal requirement.

## Re-check verdict

- License URL live and fetched: PASS
- Local LICENSE-AUDIO CC0 text present: PASS
- Ledger rows point to correct CC0 URLs: PASS
- No CC-BY/CC-BY-SA/NC files used: PASS (all CC0, so attribution column is informational only)

No defects.
