#!/usr/bin/env python3
"""The full-size art slots of the game (MEGA_PROMPT v7 of the owner, docs/VISUAL_REMAINING.md section "MEGA_PROMPT v7"): their path, size, subject and the tile of the owner's sheets each one is judged against.
One table and four jobs, so that an image made outside the repo (the owner's generator, Gemini in a browser, anything) reaches the game by commands and never by hand:

  --check          every slot file in the repo against the canon: its size, RGB (a palette PNG bands), enough colours, no clipped white, dark enough, grain
  --briefs         writes docs/art/generation_briefs.txt: the canon preamble and the subject of each slot, the file name to give the image
  --fit DIR        every DIR/<slot>.(png|jpg|webp) cut to the slot's size (cover, Lanczos), RGB, into .qa_logs/art_staged/, with a side-by-side board
                   (candidate | the sheet's tile | what the slot holds now) in .qa_logs/approvals/ to be shown to the owner; nothing reaches assets/
  --apply SLOT --approved-by "NAME DATE"   puts the staged image into its slot (a card also writes its locked variant) and adds the row of the approvals journal; the name is the owner's, typed by whoever runs it

usage: python tools/art_slots.py [--demo | --check | --briefs | --fit DIR | --apply SLOT --approved-by "NAME DATE"]
"""
import argparse
import pathlib
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHEETS = ROOT / "docs" / "art" / "style_reference"
STAGED = ROOT / ".qa_logs" / "art_staged"
BOARDS = ROOT / ".qa_logs" / "approvals"
JOURNAL = ROOT / "docs" / "VISUAL_REMAINING.md"
PREAMBLE = ("Semi-realistic gritty survival-horror game art, photographic PBR micro-detail, first-person eye-level view (camera 1.6 m, ~55 mm lens), night: near-black desaturated blue-teal shadows "
            "(#0f1314, #060f13), one warm sodium amber key light (#d4a94e) with a volumetric cone and wet-asphalt reflection, thin cold fog, subtle film grain, weathered surfaces, amber accents only from "
            "light sources, no pure white highlights, no text, no logos, no watermark, no UI elements, NOT flat design, NOT cartoon, NOT vector style.")
# the repo's own affine of the locked card from the lit one: out = k * lit + c per channel, 0..1
LOCK_K = np.array([0.439, 0.436, 0.527])
LOCK_C = np.array([0.038, 0.052, 0.050])
SCREEN_TILES = {"loading": (8, 8, 290, 278), "death": (302, 8, 568, 276), "character": (522, 290, 1048, 538), "journal": (10, 290, 508, 538)}
CARD_TILES = {
    "suburbs": (19, 385, 100, 433), "residential": (112, 385, 203, 433), "park": (207, 385, 300, 433), "school": (306, 385, 398, 433),
    "hospital": (19, 447, 107, 497), "gas_station": (112, 447, 203, 497), "police": (207, 447, 300, 497), "warehouses": (306, 447, 398, 497),
    "industrial": (19, 510, 137, 560), "substation": (144, 510, 255, 560), "power_station": (262, 510, 398, 560),
}
CARD_SUBJECTS = {
    "suburbs": "a quiet suburban street of low houses at night, one porch light, a child's bicycle on a lawn, fog",
    "residential": "a courtyard between apartment blocks, laundry lines, a few lit windows, an overturned pram",
    "park": "a park path under bare trees, one lamp over a bench, a swing set in silhouette, fog",
    "school": "a school entrance, desks piled into a barricade behind the doors, a stopped clock above",
    "hospital": "a hospital entrance, an overturned gurney and drag marks on the ground, a failing red sign",
    "gas_station": "gas station canopies over dead pumps, one flickering canopy lamp, a wet forecourt",
    "police": "a police precinct front, an abandoned patrol car with its door open and a blinking marker lamp",
    "warehouses": "a warehouse yard, stacked containers, a loading dock under one work lamp, a forklift in silhouette",
    "industrial": "an industrial zone, pipes and chimneys against the sky, steam, a rusted gantry, one sodium lamp",
    "substation": "a substation yard, transformers, a heap of luggage and a snapped cable on the ground",
    "power_station": "a turbine hall, huge dark machinery, catwalks, one emergency lamp, cold fog",
}


def slots():
    """name -> {path, size, subject, tile: (sheet, box)}."""
    s2, s1, s4 = "sheet_2_screens", "sheet_1_ui_map_panels", "sheet_4_store_feature"
    out = {
        "menu_city": dict(path="assets/ui/menu_city.png", size=(1920, 1080), tile=(s2, SCREEN_TILES["loading"]),
                          subject="a first-person eye-level street in fog at night, one street lamp on the right with a light cone and a puddle reflection, the left third darker and quieter for the menu panels, a distant silhouette"),
        "loading_street": dict(path="assets/textures/screens_v2/loading_street.png", size=(1920, 1080), tile=(s2, SCREEN_TILES["loading"]),
                               subject="a first-person street, a row of dark lamp posts with the nearest one lit, snow and fog; no progress bar (the bar is code)"),
        "death_loom": dict(path="assets/textures/screens_v2/death_loom.png", size=(1920, 1080), tile=(s2, SCREEN_TILES["death"]),
                           subject="a first-person fallen gaze, the flashlight beam along the ground, a monster silhouette far away in backlight; no captions"),
        "character_dim": dict(path="assets/textures/screens_v2/character_dim.png", size=(1920, 1080), tile=(s2, SCREEN_TILES["character"]),
                              subject="a survivor in full length with a backpack and a flashlight in the cone of a street light (third person is allowed here only), a street behind"),
        "journal_paper": dict(path="assets/textures/screens_v2/journal_paper.png", size=(1920, 1080), tile=(s2, SCREEN_TILES["journal"]),
                              subject="aged sepia paper: a manuscript, a blueprint, a photo on tape, no readable text"),
        "city_iso": dict(path="assets/textures/maps_v2/city_iso_2048.png", size=(2048, 2048), tile=(s1, (26, 88, 780, 515)),
                         subject="a dark aerial base of the city with a hex node for each district outlined in a status colour (green, yellow, red) and a glow on the restored ones; isometry is allowed here only"),
        "grid_panel": dict(path="assets/textures/maps_v2/grid_panel_512.png", size=(512, 512), tile=(s1, (796, 38, 1050, 312)),
                           subject="a dark schematic of the power grid: poles and transformer nodes, amber and green glowing nodes, thin lines; isometry is allowed here only"),
    }
    for district, box in CARD_TILES.items():
        out["card_" + district] = dict(path="assets/textures/cards/card_%s_512.png" % district, size=(512, 512), tile=(s4, box),
                                       subject="a first-person vignette of the signature of the district: " + CARD_SUBJECTS[district] + "; darkness and amber, grain")
    return out


def locked(img):
    """The locked card from the lit one, by the repo's affine."""
    a = np.asarray(img.convert("RGB")).astype(float) / 255.0
    return Image.fromarray(np.clip((a * LOCK_K + LOCK_C) * 255.0, 0, 255).astype(np.uint8), "RGB")


def verdict(img):
    """A list of what breaks the canon in an image; empty when it holds."""
    out = []
    if img.mode != "RGB":
        out.append("mode %s (RGB only: a palette PNG bands)" % img.mode)
    a = np.asarray(img.convert("RGB")).astype(np.uint8)
    small = a[::4, ::4].reshape(-1, 3)
    colours = len(np.unique(small, axis=0))
    if colours < min(4000, 0.2 * len(small)):
        out.append("only %d colours in a sample of %d pixels: it looks palette-quantised" % (colours, len(small)))
    if float((a.max(axis=2) >= 250).mean()) > 0.002:
        out.append("clipped white over %.2f %% of the frame (no pure white)" % (100.0 * float((a.max(axis=2) >= 250).mean())))
    if float(a.mean()) > 70.0:
        out.append("mean level %.0f: not a night image" % float(a.mean()))
    lum = np.asarray(img.convert("L")).astype(float)
    noise = float(np.abs(lum[1:-1, 1:-1] * 4 - lum[:-2, 1:-1] - lum[2:, 1:-1] - lum[1:-1, :-2] - lum[1:-1, 2:]).mean())
    if noise < 1.2:
        out.append("no grain (high-frequency level %.2f)" % noise)
    return out


def check():
    bad = 0
    for name, s in slots().items():
        path = ROOT / s["path"]
        if not path.exists():
            print("MISSING %-18s %s" % (name, s["path"]))
            bad += 1
            continue
        img = Image.open(path)
        problems = verdict(img) + (["size %dx%d, the slot is %dx%d" % (img.size + s["size"])] if img.size != s["size"] else [])
        print("%-5s %-18s %s" % ("FAIL" if problems else "ok", name, "; ".join(problems)))
        bad += bool(problems)
    return bad


def briefs():
    lines = ["Generation briefs for the full-size art slots (written by tools/art_slots.py --briefs; the canon is MEGA_PROMPT v7, docs/VISUAL_REMAINING.md).",
             "Each brief is the preamble below, a space, and the subject of the slot. Name the image <slot>.png and put it in one folder, then: python tools/art_slots.py --fit <folder>.",
             "Reference for img2img: the tile of the sheets named on each line (docs/art/style_reference/).", "", "PREAMBLE: " + PREAMBLE, ""]
    for name, s in slots().items():
        lines += ["%s  (%dx%d, goes to %s; tile %s %s)" % (name, s["size"][0], s["size"][1], s["path"], s["tile"][0], s["tile"][1]), "  " + s["subject"], ""]
    (ROOT / "docs" / "art").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs" / "art" / "generation_briefs.txt").write_text("\n".join(lines), encoding="utf-8")
    return len(slots())


def cover(img, size):
    """The image scaled to cover the size and cut from its middle."""
    scale = max(size[0] / img.width, size[1] / img.height)
    img = img.resize((max(size[0], round(img.width * scale)), max(size[1], round(img.height * scale))), Image.LANCZOS)
    left, top = (img.width - size[0]) // 2, (img.height - size[1]) // 2
    return img.crop((left, top, left + size[0], top + size[1]))


def board(name, candidate, s):
    """Candidate | the sheet's tile | what the slot holds now, each scaled to 540 px high, labelled outside the art."""
    sheet, box = s["tile"]
    tile = Image.open(SHEETS / (sheet + ".webp")).convert("RGB").crop(box)
    now = Image.open(ROOT / s["path"]).convert("RGB") if (ROOT / s["path"]).exists() else Image.new("RGB", (64, 64))
    parts = [(label, im.resize((max(1, round(im.width * 540 / im.height)), 540), Image.LANCZOS)) for label, im in (("CANDIDATE", candidate), ("SHEET TILE", tile), ("NOW", now))]
    out = Image.new("RGB", (sum(p.width for _, p in parts) + 20 * (len(parts) + 1), 540 + 60), (20, 20, 20))
    draw, x = ImageDraw.Draw(out), 20
    for label, im in parts:
        out.paste(im, (x, 40))
        draw.text((x, 12), "%s  %s" % (name, label), fill=(200, 200, 190))
        x += im.width + 20
    return out


def fit(folder):
    STAGED.mkdir(parents=True, exist_ok=True)
    BOARDS.mkdir(parents=True, exist_ok=True)
    done = 0
    for name, s in slots().items():
        found = [p for ext in ("png", "jpg", "jpeg", "webp") for p in [pathlib.Path(folder) / ("%s.%s" % (name, ext))] if p.exists()]
        if not found:
            continue
        img = cover(Image.open(found[0]).convert("RGB"), s["size"])
        img.save(STAGED / (name + ".png"), compress_level=9)
        board(name, img, s).save(BOARDS / (name + "_board.png"), compress_level=9)
        problems = verdict(img)
        print("%-18s staged; board .qa_logs/approvals/%s_board.png; %s" % (name, name, "; ".join(problems) or "canon holds"))
        done += 1
    return done


def apply(name, who):
    s = slots()[name]
    src = STAGED / (name + ".png")
    if not src.exists():
        sys.exit("nothing staged for " + name)
    if not re.search(r"\w+.*\d{4}-\d{2}-\d{2}", who):
        sys.exit('--approved-by wants a name and a date, e.g. "Maxsim 2026-10-30"')
    img = Image.open(src).convert("RGB")
    img.save(ROOT / s["path"], compress_level=9)
    if name.startswith("card_"):
        locked(img).save(ROOT / s["path"].replace("_512.png", "_locked_512.png"), compress_level=9)
    text = JOURNAL.read_bytes().decode("utf-8")
    eol = "\r\n" if "\r\n" in text else "\n"
    row = "| %s | the slot `%s` filled with a full-size image (side by side: `.qa_logs/approvals/%s_board.png`) | APPROVED by %s |" % (name, s["path"], name, who)
    JOURNAL.write_bytes((text.rstrip("\r\n") + eol + row + eol).encode("utf-8"))
    print("applied", name, "->", s["path"])


def demo():
    table = slots()
    assert len(table) == 7 + len(CARD_TILES) and all(s["size"][0] > 0 for s in table.values())
    flat = Image.new("P", (64, 64))
    assert any("palette" in p for p in verdict(flat)), "a palette image is refused"
    rng = np.random.default_rng(1)
    night = Image.fromarray(np.clip(rng.normal(22, 9, (96, 96, 3)), 0, 255).astype(np.uint8), "RGB")
    assert verdict(night) == [], verdict(night)
    assert any("white" in p for p in verdict(Image.new("RGB", (64, 64), (255, 255, 255)))), "white is refused"
    assert cover(night, (192, 108)).size == (192, 108), "cover cuts to the slot size"
    lit = Image.new("RGB", (4, 4), (200, 150, 100))
    assert locked(lit).getpixel((0, 0)) == (int((200 / 255 * 0.439 + 0.038) * 255), int((150 / 255 * 0.436 + 0.052) * 255), int((100 / 255 * 0.527 + 0.05) * 255)), "the locked card follows the affine"
    for s in table.values():
        sheet, box = s["tile"]
        wide = Image.open(SHEETS / (sheet + ".webp"))
        assert 0 <= box[0] < box[2] <= wide.width and 0 <= box[1] < box[3] <= wide.height, "the tile lies on its sheet"
    print("art_slots demo OK (%d slots; a palette image, white and a grainless frame are refused; cover, the locked affine and the tiles are in order)" % len(table))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--briefs", action="store_true")
    ap.add_argument("--fit")
    ap.add_argument("--apply")
    ap.add_argument("--approved-by", default="")
    a = ap.parse_args()
    if a.demo:
        demo()
    elif a.check:
        sys.exit(1 if check() else 0)
    elif a.briefs:
        print("wrote docs/art/generation_briefs.txt,", briefs(), "slots")
    elif a.fit:
        print(fit(a.fit), "image(s) staged")
    elif a.apply:
        apply(a.apply, a.approved_by)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
