# Quarantine audit

Static-only manifest for `res://_QUARANTINE/` (the checkout path is
`_QUARANTINE/`). No Godot engine was started. No asset was deleted, moved,
renamed, or edited. The generated source of truth is
`python3 tools/quarantine_audit.py --check`.

## Method and proof commands

The two reference passes are intentionally independent:

```text
$ python3 tools/quarantine_audit.py --check
verdict counts: {"AUTO-DELETABLE": 10, "KEEP-LIVE": 16, "KEEP-PLANNED": 24, "UNCERTAIN": 36}
check: PASS (UNCERTAIN means owner eyes, not a gate failure)
```

- **Pattern A** searches the full candidate path, both as `res://...` and as
  a repository-relative path, in `scripts/`, `scenes/`, `components/`,
  `data/`, and `addons/` text resources.
- **Pattern B** searches the exact candidate basename with path-token
  boundaries. It is not a restatement of Pattern A and does not treat
  `vfx_muzzle_flash.tscn` as the quarantined basename
  `muzzle_flash.tscn`.
- The dynamic pass searches format/concatenated loads, variable
  `load()`/`preload()` calls, `ResourceLoader`, `DirAccess`, `list_dir`, and
  district/material or texture assignments. It is a warning surface, never a
  deletion proof.
- Each candidate was also checked against all four named files:
  `docs/VISUAL_PASS.md`, `docs/STORE_KIT.md`, `docs/CARD_ART_BRIEF.md`, and
  `docs/KNOWN_ISSUES.md`; the tool records the four per-file results in its
  JSON manifest. Wider documentation was searched for the final disposition.

Inventory proof:

```text
$ find _QUARANTINE -type f | sort | wc -l
10
```

The table's **A**, **B**, **D**, and **docs** cells are output snippets from
that command's corresponding scan sections. `—` means that pass returned no
line; it does not mean a binary was opened by an engine.

## Per-file verdict table

| File | A — full path | B — basename | D — dynamic pass | Doc anchor | Verdict |
|---|---|---|---|---|---|
| `_QUARANTINE/assets/fonts/ChakraPetch-Bold.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:56` | **AUTO-DELETABLE** |
| `_QUARANTINE/assets/fonts/Rajdhani-SemiBold.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:56` | **AUTO-DELETABLE** |
| `_QUARANTINE/assets/fonts/SairaCondensed-Bold.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:56` | **AUTO-DELETABLE** |
| `_QUARANTINE/assets/fonts/SairaCondensed-Regular.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:56` | **AUTO-DELETABLE** |
| `_QUARANTINE/assets/fonts/bebas_neue_bold.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:53` | **AUTO-DELETABLE** |
| `_QUARANTINE/assets/fonts/roboto_condensed.ttf` | — | — | none | `docs/ERROR_LOG_FINAL.md:53` | **AUTO-DELETABLE** |
| `_QUARANTINE/scenes/effects/blood_particles.tscn` | — | — | none | `docs/ERROR_LOG_FINAL.md:74` | **AUTO-DELETABLE** |
| `_QUARANTINE/scenes/effects/footstep_dust.tscn` | — | — | none | `docs/ERROR_LOG_FINAL.md:74` | **AUTO-DELETABLE** |
| `_QUARANTINE/scenes/effects/hit_spark.tscn` | — | — | none | `docs/ERROR_LOG_FINAL.md:74` | **AUTO-DELETABLE** |
| `_QUARANTINE/scenes/effects/muzzle_flash.tscn` | — | — | none | `docs/ERROR_LOG_FINAL.md:74` | **AUTO-DELETABLE** |

All ten quarantined files have A=0 and B=0. The report's explicit prior
record is the reason they are **AUTO-DELETABLE** recommendations, not an
instruction to remove them here: `docs/REPORT_FINAL_POLISH.md:9-15` records
the six fonts and four duplicate effect scenes as quarantined after a
zero-reference check; `docs/ERROR_LOG_FINAL.md:56,74` records the zero-link
checks. `AUTO-DELETABLE` means “safe candidate for a later owner-run delete”
under this static audit, not “deleted in this commit.”

## Five manual live-grep spot checks

These were run after the indexed pass. The second expression is boundary-safe
for the basename; it avoids the false positive where `muzzle_flash.tscn` is a
substring of `vfx_muzzle_flash.tscn`.

```text
$ rg -n --fixed-strings 'res://_QUARANTINE/scenes/effects/blood_particles.tscn' scripts scenes components data addons || true
$ rg -n -e '(^|[/" ])blood_particles\.tscn([" ]|$)' scripts scenes components data addons || true
(no matches above = zero)

$ rg -n --fixed-strings 'res://_QUARANTINE/assets/fonts/Rajdhani-SemiBold.ttf' scripts scenes components data addons || true
$ rg -n -e '(^|[/" ])Rajdhani-SemiBold\.ttf([" ]|$)' scripts scenes components data addons || true
(no matches above = zero)

$ rg -n --fixed-strings 'res://_QUARANTINE/scenes/effects/muzzle_flash.tscn' scripts scenes components data addons || true
$ rg -n -e '(^|[/" ])muzzle_flash\.tscn([" ]|$)' scripts scenes components data addons || true
(no matches above = zero; the live lines use vfx_muzzle_flash.tscn)

$ rg -n --fixed-strings 'res://_QUARANTINE/assets/fonts/SairaCondensed-Bold.ttf' scripts scenes components data addons || true
$ rg -n -e '(^|[/" ])SairaCondensed-Bold\.ttf([" ]|$)' scripts scenes components data addons || true
(no matches above = zero)

$ rg -n --fixed-strings 'res://_QUARANTINE/' scripts scenes components data addons || true
$ rg -n -e '(^|[/" ])_QUARANTINE/' scripts scenes components data addons || true
(no matches above = zero)
```

The named review-doc command also produced this guard result:

```text
$ for d in docs/VISUAL_PASS.md docs/STORE_KIT.md docs/CARD_ART_BRIEF.md docs/KNOWN_ISSUES.md; do rg -n -i '(_QUARANTINE|assets/textures/(surfaces|ui)|surfaces/|textures/ui)' "$d" || true; done
KNOWN_ISSUES.md:42-43: the newly spotted res://_QUARANTINE directory; no per-file keep/planned claim
```

That last note is why the per-file disposition uses the older explicit audit
record rather than silently treating the quarantine directory mention as a
planned feature.

## Output classes

- **AUTO-DELETABLE** — zero A/B hits plus an explicit dead/duplicate/zero-link
  record; owner may decide later. No deletion was performed.
- **KEEP-LIVE** — a source/scenes/data consumer was found. None occur in this
  quarantine root today.
- **KEEP-PLANNED** — zero static hits but a documented future, delivery, or
  wiring note exists. None occur in this quarantine root today.
- **UNCERTAIN** — owner eyes required. None remain in this root after the
  explicit quarantine record was cross-checked.

## Scope review

```text
$ git diff --stat -- docs/QUARANTINE_AUDIT.md docs/SURFACES_UI_NARROWING.md tools/quarantine_audit.py
# expected changed paths: these three files only; no asset path appears
```

Self-review: quarantine inventory is complete; both grep passes and five live
greps are recorded; no deletion or `docs/SIZE_BUDGET.md` edit was made.
