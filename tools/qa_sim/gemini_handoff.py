# -*- coding: utf-8 -*-
"""P3 (Session 24): the handoff document for a generator run (Gemini or any other) and for the pass that integrates its files.

usage: python tools/qa_sim/gemini_handoff.py [--write] [--check] [--demo]    (--write writes docs/GEMINI_HANDOFF.md)
It reads the music brief (the 11 lit beds), the music recipe (19 tracks, checked against the disk), the music prompt list (which section holds each prompt),
the music spec's house law and the card art brief (the seven district specs, the prompts, the acceptance checks, the cluster targets) and writes one document,
so a number or a prompt cannot be typed wrong. --check fails when the written file is not what the sources give now (a source moved, a file appeared on disk).
No audio or image is made here, and nothing is fetched.
"""
import pathlib
import re
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = "docs/GEMINI_HANDOFF.md"
DISTRICTS = ("park", "school", "hospital", "gas_station", "police", "warehouses", "substation")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8").replace("\r\n", "\n")


def png_size(rel):
    p = ROOT / rel
    if not p.is_file():
        return None
    d = p.read_bytes()[:24]
    return struct.unpack(">II", d[16:24]) if d[:8] == b"\x89PNG\r\n\x1a\n" else None


def lit_beds(text):
    rx = re.compile(r"^\| (\w+) \| `([^`]+)` \| (yes|no) \| ([\d.]+) \| ([^|]+) \| (-?[\d.]+) \| (-?[\d.]+) \|$", re.M)
    return rx.findall(text)


def recipe_rows(text):
    return re.findall(r"^\|\s*(\d+)\s*\|\s*`([^`]+)`\s*([^|]*)\|\s*([^|]*)\|", text, re.M)


def prompt_sections(text):
    return {m.group(2): m.group(1) for m in re.finditer(r"^### (\d+\.\d+) `([^`]+)`", text, re.M)}


def district_blocks(brief):
    """{district: (tagline, {bullet: text}, [(prompt, negative)])} from section 4 of the card brief; Flux candidates 1 and 2."""
    out = {}
    body = brief[brief.index("## 4. The 7 district specs"):brief.index("## 5. Generation notes")]
    for m in re.finditer(r"^### 4\.\d `(\w+)` — \"([^\"]+)\"\n(.*?)(?=^### 4\.\d |\Z)", body, re.M | re.S):
        name, tag, block = m.groups()
        bullets = {k: " ".join(v.split()) for k, v in re.findall(r"^- \*\*(Subject|Composition|Palette|Mood)\*\*: (.*?)(?=\n- \*\*|\n\n)", block, re.M | re.S)}
        flux = block[block.index("**Flux.1-dev"):]
        prompts = []
        for n in (1, 2):
            pm = re.search(r"^%d\. `([^`]+)`\n\s+`negative: ([^`]+)`" % n, flux, re.M)
            prompts.append((pm.group(1), pm.group(2)) if pm else ("", ""))
        out[name] = (tag, bullets, prompts)
    return out


def accents(brief):
    sec = brief[brief.index("## 3. District accents"):brief.index("## 4. The 7 district specs")]
    return {m.group(1): [c.strip() for c in m.group(2).split("|")] for m in re.finditer(r"^\| (\w+) \| (.+) \|$", sec, re.M) if m.group(1) in DISTRICTS}


def size(s):
    return "%d x %d" % s if s else "**absent**"


def render():
    brief_music = read("docs/MUSIC_BRIEF.md")
    recipe = read("docs/MUSIC_RECIPE.md")
    spec = read("docs/MUSIC_SPEC.md")
    plist = read("docs/MUSIC_PROMPTS_FULL.md")
    cards = read("docs/CARD_ART_BRIEF.md")
    law = [ln.strip() for ln in spec.splitlines() if ln.startswith("| Ambience/music beds loudness") or ln.startswith("| Stingers/SFX loudness")]
    sections = prompt_sections(plist)
    beds = lit_beds(brief_music)
    rec = recipe_rows(recipe)
    blocks = district_blocks(cards)
    acc = accents(cards)
    checks = cards[cards.index("### 6.1 Automatic validation"):cards.index("Re-run after art lands")]
    table = [ln for ln in checks.splitlines() if ln.startswith("|")]
    cluster = re.search(r"min cross\nHamming \*\*(\d+)\*\* \(floor (\d+)\), MAD ([\d.]+)[^,]*, k-means\(k=11\) → 11 singleton", cards)
    L = []
    a = L.append
    a("# Handoff for a generator run and for the pass that integrates it (Session 24, P3)")
    a("")
    a("Written by `python tools/qa_sim/gemini_handoff.py --write` from `docs/MUSIC_BRIEF.md`, `docs/MUSIC_RECIPE.md`, `docs/MUSIC_SPEC.md`, `docs/MUSIC_PROMPTS_FULL.md` and `docs/CARD_ART_BRIEF.md`;")
    a("`--check` (a static gate) fails when a source moved or a file appeared on disk. **Nothing here was made**: no audio, no image, no download. The tools of a generator (names, limits, the length of a take) change; what")
    a("a given product does today is UNVERIFIABLE-HERE and is the owner's to read on the day.")
    a("")
    a("## 1. What is asked, and what is not")
    a("")
    a("- **Asked of the generator:** audio for the tracks of section 2 and seven portrait photographs of section 3, rendered from the prompts that are already written (the music list `docs/MUSIC_PROMPTS_FULL.md`, absorbed from")
    a("  `origin/claude/keen-cori-0sc9uo`; the card prompts of `docs/CARD_ART_BRIEF.md` section 4). The generator's output is raw material: it is trimmed, graded and gated by the tools of section 4 before it is a game file.")
    a("- **Not asked, not done:** nothing is wired by this document, no binary is committed with it, and no file lands in `assets/` or `content/` until the integration checklist of section 4 has been run on it. The game runs without any of")
    a("  these files: every music path is guarded by `ResourceLoader.exists` (`scripts/systems/music_manager.gd`), and the cards exist (section 3.1). A missing track is an upgrade not made, never a hole.")
    a("- **Language:** English for every prompt (the house prompts are English; `docs/MUSIC_PROMPTS_FULL.md` has the same 69 in one list; a Russian phone copy of them is on `origin/claude/keen-cori-0sc9uo`, not absorbed).")
    a("")
    a("## 2. Music")
    a("")
    a("### 2.1 The house law (`docs/MUSIC_SPEC.md`)")
    a("")
    for ln in law:
        a("> " + ln)
    a("")
    a("Every bed is a seamless loop of 36 s in the lit-bed brief, mono, 44.1 kHz, OGG quality 4; a take is trimmed at a zero crossing with 3 ms edge fades, loudness-normalised to the figure above, and checked against the true-peak")
    a("ceiling of -1.5 dBFS. `python tools/qa_sim/audio_loudness.py --check` reads every shipped file.")
    a("")
    generated = sum(1 for b in beds if b[1].startswith("assets/audio/music/"))
    a("### 2.2 The 11 lit beds: all on disk (%d generated tracks of Session 27, %d synthesized loops), a composed replacement is an upgrade" % (generated, len(beds) - generated))
    a("")
    a("From `docs/MUSIC_BRIEF.md` (generated from `AMBIENCE_LIT_BY_DISTRICT`); the measures are of the files today. The brief and the prompt of each bed are in that document, one row per district.")
    a("")
    a("| District | Target file | On disk | Length (s) | Channels, rate | LUFS | True peak (dBFS) |")
    a("|---|---|---|---|---|---|---|")
    for d, f, disk, ln, ch, lufs, tp in beds:
        a("| %s | `%s` | %s | %s | %s | %s | %s |" % (d, f, disk, ln, ch.strip(), lufs, tp))
    a("")
    spans = [float(b[3]) for b in beds if b[1].startswith("assets/audio/music/")]
    a("The length of 36 s is the contract of the synthesized beds%s." % ("; the generated tracks are cut at a whole number of bars of their tempo (`docs/MUSIC_RECIPE.md`, %.1f to %.1f s), and the loader loops a file of any length (`_force_loop`)" % (min(spans), max(spans)) if spans else ""))
    a("The brief's prompts end with the common line: *instrumental only, no vocals, no drums, seamless 36 s loop, mono, about -18 LUFS*.")
    a("")
    a("### 2.3 The 19 tracks of the music recipe, against the disk")
    a("")
    a("`docs/MUSIC_RECIPE.md` is the ordered list (2026-09-21). \"On disk\" is a check of `assets/audio/<target>` now; the prompt is in the section of `docs/MUSIC_PROMPTS_FULL.md` named in the last column.")
    a("")
    a("| # | Target | State in the recipe | Length | On disk | Prompt section |")
    a("|---|---|---|---|---|---|")
    missing = 0
    for n, path, note, length in rec:
        disk = (ROOT / "assets" / "audio" / path).is_file()
        missing += not disk
        a("| %s | `%s` | %s | %s | %s | %s |" % (n, path, " ".join(note.split()).strip("() ") or "-", " ".join(length.split()), "yes" if disk else "**no**", sections.get(path, "-")))
    a("")
    a("**%d of %d targets are not on disk.** They are the true gaps. An absent file is skipped by the guards of `scripts/systems/music_manager.gd` (`ResourceLoader.exists`), and `docs/MUSIC_SPEC.md` names the fallback of each row (the menu's is `abandoned_hallways.mp3`)." % (missing, len(rec)))
    a("The 11 beds of 2.2 are not in this list: they are upgrades.")
    a("")
    a("### 2.4 After a take comes back")
    a("")
    a("1. Trim to the loop length of the table at a zero crossing, 3 ms edge fades; the take must end where it began (same pad level, no reverb tail cut; crossfade the last 2 s under the first 2 s when it rings out).")
    a("2. Normalise to the house law, export OGG quality 4, mono, 44.1 kHz (`.wav` only where the target says `.wav`), save to the **exact path** of the table.")
    a("3. Add a row to `docs/ASSET_LICENSES.md` (`path | origin | license | attribution | notes`): the generator, its version, the prompt id and the licence terms of the day. A track with no row is not committed.")
    a("4. `python tools/qa_sim/audio_loudness.py --check`, then `python tools/qa_sim/music_brief.py --check`, then `bash tools/check.sh --static`.")
    a("")
    a("## 3. The seven district cards")
    a("")
    a("### 3.1 The state today")
    a("")
    a("`docs/CARD_ART_BRIEF.md` says 11 of 11 districts have a unique card (2026-09-14): the seven below were generated in-session from the section 4 prompts, graded by `scripts/regen_cards_v2.py` (all 8 checks pass), and are in the game. What stays open there")
    a("is the frozen suburbs and residential twin (aHash 1); the seven masters, their twins and the in-game textures have licence rows (`docs/ASSET_LICENSES.md`), and the raws were not kept, so no row can exist for them. A new run is a")
    a("replacement of art that works, so it is the owner's choice and not a gap.")
    a("")
    a("| District | Master (1024 x 1536) | 512 twin | In game |")
    a("|---|---|---|---|")
    for d in DISTRICTS:
        m = png_size("content/cards/district_%s.png" % d)
        t = png_size("content/cards/twins/card_%s_512.png" % d)
        g = png_size("assets/textures/cards/card_%s_512.png" % d)
        a("| `%s` | %s | %s | %s |" % (d, size(m), size(t), size(g)))
    a("")
    a("### 3.2 Settings, seeds and what to ask for")
    a("")
    a("- **Deliverable:** one raw per district, portrait 2:3, 1024 x 1536 (a generator that returns another size is cropped to 2:3 around the light and resized with LANCZOS *before* grading), PNG, no text, no watermark.")
    a("- **Common to all seven:** street level or human scale, 35 mm look, no people, one light source, fog or mist, at least a third of the frame empty, the subject filling the central horizontal band (the card shows a 230 x 84 strip).")
    a("- **Wording:** the Flux wording of section 4 (it is the wording that produced the cards on 2026-09-14: `docs/CARD_ART_BRIEF.md` section 6.3; the generator did not honour Midjourney parameters, so `--ar` and `--style` are dropped and a")
    a("  portrait sentence added). The negative prompt is used verbatim; add `human hands, feet, partial body` when people appear.")
    a("- **Seeds:** none is recorded for the raws of 2026-09-14 (the in-session generator exposes none); record the seed where a product gives one, in the licence row. The pipeline's own seed is fixed: `scripts/regen_cards_v2.py` runs with")
    a("  seed 13 and a film grain of amplitude 0.04, and two runs on the same input are byte-identical.")
    a("- **Reject before grading:** visible people or faces, more than one light source, green, magenta or neon chroma, readable text, a watermark, pure black or white, daytime or blue hour, a glossy or HDR look.")
    a("")
    a("### 3.3 The seven specs")
    a("")
    a("Each block is `docs/CARD_ART_BRIEF.md` section 4 for that district: the canon accent row of section 3, the four bullets, and the Flux candidates 1 and 2 with their negatives, verbatim. Candidate 3 and the Midjourney wording are in the brief.")
    a("")
    for i, d in enumerate(DISTRICTS, 1):
        tag, bullets, prompts = blocks[d]
        a("#### 3.3.%d `%s`: \"%s\"" % (i, d, tag))
        a("")
        row = acc.get(d, [])
        if len(row) >= 4:
            a("Canon row (accent | sky and ambient | weather | rule): %s." % " | ".join(row[:4]))
            a("")
        for key in ("Subject", "Composition", "Palette", "Mood"):
            a("- **%s:** %s" % (key, bullets.get(key, "-")))
        a("")
        for n, (p, neg) in enumerate(prompts, 1):
            a("Candidate %d prompt:" % n)
            a("")
            a("```text")
            a(p)
            a("```")
            a("")
            a("Candidate %d negative:" % n)
            a("")
            a("```text")
            a(neg)
            a("```")
            a("")
    a("### 3.4 Acceptance: the eight checks and the cluster targets")
    a("")
    a("`python scripts/regen_cards_v2.py --raw-dir <raws> --out content/cards --emit-512 content/cards/twins --report report.json` exits 1 on any FAIL; no threshold is loosened per district. The checks (`docs/CARD_ART_BRIEF.md` section 6.1):")
    a("")
    L.extend(table)
    a("")
    if cluster:
        a("Cluster targets (`python scripts/audit_card_clusters.py --images`): every card distinct from every other; aHash Hamming at least **%s**, 32 x 32 grey MAD at least 12, k-means (k = 11) giving 11 singleton clusters." % cluster.group(2))
        a("The shipped set measures a minimum cross Hamming of **%s** and a MAD from **%s**; a new card that does not keep the floors is rejected, and the suburbs and residential keeper pair is the one named frozen exception." % (cluster.group(1), cluster.group(3)))
    a("")
    a("## 4. Integration checklist for the final pass")
    a("")
    a("1. **Licence rows first** (`docs/ASSET_LICENSES.md`), one per accepted file. 2. **Cards:** grade (3.4), then `python scripts/make_locked_cards.py` for the `_locked_512` variants, `python scripts/make_card_contact_sheet.py`, and the audit of 3.4;")
    a("   the twins replace `assets/textures/cards/card_<district>_512.png`. 3. **Music:** section 2.4, files at the exact paths; a track the game does not load yet needs the wiring named in `docs/MUSIC_SPEC.md` for its row, which is a code change")
    a("   with its own AF2 pair. 4. **Gates:** `bash tools/check.sh --static` (the audio and card gates, `gitignore_check`, `secret_scan`), `python tools/af5_check.py`. 5. **Frames:** a card shows in the collection screen only: re-shoot the")
    a("   frames of the collection view and read them (`docs/stills/`), or declare the reach in `tools/qa_sim/af3_f4_scope.tsv` if a runtime path changed. 6. **One launch:** `bash tools/check.sh --all`, then the 3-seed bot if a track was wired")
    a("   (`tools/qa_sim/autoplay_bot`). 7. **Bundle:** one export, then `python tools/qa_sim/aab_check.py build/tls.aab` (the bundle scan, `integrity` and `refs`), `version/code` raised.")
    a("")
    a("## 5. Owner rows that are not for a generator (documented, not implemented)")
    a("")
    a("| Row | State today | What the owner decides | What it touches |")
    a("|---|---|---|---|")
    a("| Crash reporting (Firebase, Crashlytics) | absent: `docs/PRIVACY_AUDIT.md` lists no analytics or crash SDK, and the bundle has no network call from a screen | whether the game reports crashes at all | the privacy policy and the data-safety answers change from \"collects nothing\" (`docs/STORE_SUBMISSION.md` sections 3 and 5), a Gradle plugin and a `google-services.json` (ignored by `.gitignore`), a consent screen where the law asks for one |")
    a("| Unlockable cosmetics | two skins and a starter bundle exist and sell for coins in the pause-menu shop (`data/shop/skin_survivor_ashen.tres` and `skin_survivor_rust.tres`, 2,000 coins each; `bundle_starter.tres`, 4,000 coins at 30 % off; `scripts/economy/shop_service.gd:8-9`, `ShopItem.Kind.SKIN`), applied as a rim colour and a darker body tint (`scripts/player/player_visual.gd:6-26`); none unlocks by play, and nothing else is cosmetic | whether more skins ship, whether any unlocks by play (an achievement, a level), and that there is still no purchase with money (the store answers say none) | art, `data/shop/`, the `SHOP_ITEM_SKIN_*` keys of 13 locales, and a save field only for a cosmetic that is not a shop item (`docs/SAVE_MIGRATION_MATRIX.md`) |")
    a("| Survivor and Dark endings | a death resolves to Dark or Survivor (`EndingsManager.evaluate_death_ending`, GDD 12.4), the death screen keeps one picture (`assets/textures/screens_v2/death_loom.png`) and the five ending plates of `assets/store/endings/` ship in the bundle with no script that loads them | whether the death screen shows the earned plate, and whether Survivor and Dark are two endings or one | `scripts/ui/death_screen.gd`, `scripts/ui/win_screen.gd`, a frame re-shoot, the plates' place in the export filter (`docs/CORRECTION_LOG.md` 182) |")
    a("| Touch feel on a device | measured only on a desktop with the touch probe (34 checks, 0 fails: `docs/artifacts/rc16/proofs/s22c_af2_post.attach.gate_touch_probe_scene.log`): the dead zone, the curve, the haptics and the calibration are the phone test's questions (U1, U5, U6, U13 of `docs/UNVERIFIABLE_HERE.md`) | the constants, after the numbers of a phone | `scripts/ui/virtual_joystick.gd`, `docs/RELEASE_RUNBOOK.md` section 4 |")
    a("| Remaining music | the %d targets of 2.3 and the upgrade of the 11 beds of 2.2 | which of them are worth a take | section 2.4 and the licence ledger |" % missing)
    a("| Seven district card photographs | graded generated cards are in the game (3.1), with licence rows; the open point is a replacement if better art exists | replace or keep | section 3 and 4 |")
    a("")
    return "\n".join(L) + "\n"


def demo():
    beds = lit_beds("| suburbs | `assets/audio/ambience/districts/suburbs_lit.ogg` | yes | 36.0 | 1, 44100 | -18.8 | -9.1 |\n")
    assert beds == [("suburbs", "assets/audio/ambience/districts/suburbs_lit.ogg", "yes", "36.0", "1, 44100", "-18.8", "-9.1")], beds
    rows = recipe_rows("| 2 | `music/suburbs.ogg` (NEW) | 37.333 s (14 bars @ 90 BPM) | `Instrumental ...` |\n")
    assert rows == [("2", "music/suburbs.ogg", "(NEW) ", "37.333 s (14 bars @ 90 BPM) ")], rows
    assert prompt_sections("### 2.1 `music/suburbs.ogg` — 37.333 s\n") == {"music/suburbs.ogg": "2.1"}
    brief = ("## 4. The 7 district specs\n### 4.1 `park` — \"alive\"\n- **Subject**: a carousel\n  at night.\n- **Mood**: waiting.\n\n"
             "**Flux.1-dev (3):**\n\n1. `P one`\n   `negative: N one`\n2. `P two`\n   `negative: N two`\n\n## 5. Generation notes\n")
    got = district_blocks(brief)
    assert got["park"][1]["Subject"] == "a carousel at night." and got["park"][2] == [("P one", "N one"), ("P two", "N two")], got
    print("gemini_handoff demo OK (a lit bed row, a recipe row, a prompt section, a district block with two candidates)")


def main():
    args = sys.argv[1:]
    if "--demo" in args:
        demo()
        return 0
    text = render()
    if "--write" in args:
        (ROOT / OUT).write_text(text, encoding="utf-8", newline="\n")
        print("wrote %s (%d lines)" % (OUT, text.count("\n")))
        return 0
    if "--check" in args:
        have = read(OUT) if (ROOT / OUT).is_file() else ""
        if have != text:
            print("gemini_handoff: %s is not what its sources give now; run --write" % OUT)
            return 1
        print("gemini_handoff: %s matches its sources" % OUT)
        return 0
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
