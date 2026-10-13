# -*- coding: utf-8 -*-
"""Store listing audit (Session 23, S1): the listing of store/listing.md in all 13 locales against the limits of the store and against the code.

  L1 title of at most 30 characters; L2 short description of at most 80 and the length the listing declares; L3 full description of at most 4000.
  L4 the set of whole numbers of a locale's texts is the English set (the same claims in every language; 1 is left out: it is "first person" in Korean); L5 the English numbers are what the code holds
     (districts, monsters, endings, languages, achievements, daily templates, music layers); L6 the features the English text names exist in the scripts.
  L7 the store title of a locale is the in-game menu_title (case aside). ASO: how many of the locale's own tags occur in its texts.

usage: python tools/qa_sim/listing_audit.py [--write store/LISTING_AUDIT.md] [--demo]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LISTING = ROOT / "store" / "listing.md"
LOCALES = ["en", "ru", "es", "de", "fr", "it", "pt_BR", "tr", "ja", "ko", "zh", "zh_TW", "ar"]
TITLE_MAX, SHORT_MAX, FULL_MAX = 30, 80, 4000
# the English claim -> (what the code holds, how it is read)
FEATURES = {
    "joystick": ("scripts/ui/virtual_joystick.gd", r"class_name|extends"), "double-tap dodge": ("scripts/player/player_3d.gd", r"request_dodge"),
    "workbench": ("scripts/crafting/workbench_logic.gd", r"RECIPES|medkit"), "New Game+": ("scripts/systems/new_game_plus.gd", r"activate_ng_plus"),
    "daily challenges": ("scripts/systems/daily_challenge_manager.gd", r"_complete"), "photo mode": ("scripts/ui/photo_mode.gd", r"capture|photo"),
}


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")


def block_after(text, start):
    m = re.search(r"```\n(.*?)```", text[start:], re.S)
    return m.group(1).strip() if m else ""


def parse(text):
    """{locale: {"title", "short", "short_declared", "full", "tags"}}"""
    out = {}
    master = text.index("## Full description")
    for loc, tag in (("en", "EN"), ("ru", "RU")):
        title = re.search(r"^- \*\*%s:\*\* (.+)$" % tag, text[text.index("## Title"):], re.M).group(1).strip()
        short = re.search(r"^- \*\*%s \((\d+)/80[^)]*\):\*\* `(.+)`$" % tag, text, re.M)
        full = block_after(text, text.index("### %s" % tag, master))
        out[loc] = {"title": title, "short": short.group(2), "short_declared": int(short.group(1)), "full": full + "\n" + master_bullets(text, tag), "tags": tags(text, tag)}
    for loc in LOCALES[2:]:
        m = re.search(r"^### %s — .*?(?=^### |\Z)" % re.escape(loc), text, re.M | re.S)
        sec = m.group(0)
        title = re.search(r"^- \*\*Title:\*\* (.+)$", sec, re.M).group(1).strip()
        short = re.search(r"^- \*\*Short \((\d+)/80\):\*\* (.+)$", sec, re.M)
        full = block_after(sec, sec.index("**Full description:**"))
        bullets = sec[sec.index("**Feature bullets:**"):sec.index("- **ASO tags:**")] if "**Feature bullets:**" in sec else ""
        t = re.search(r"^- \*\*ASO tags:\*\* (.+)$", sec, re.M)
        out[loc] = {"title": title, "short": short.group(2).strip(), "short_declared": int(short.group(1)), "full": full + "\n" + bullets,
                    "tags": [x.strip() for x in t.group(1).split(",")] if t else []}
    return out


def master_bullets(text, tag):
    sec = text[text.index("## Feature bullets"):text.index("## Tags / keywords")]
    part = sec[sec.index("### %s" % tag):]
    nxt = part.find("### ", 5)
    return part[:nxt] if nxt > 0 else part


def tags(text, tag):
    """The backticked tags and the keyword list of the master EN or RU block."""
    sec = text[text.index("## Tags / keywords"):]
    part = sec[sec.index("### %s" % tag):]
    nxt = part.find("\n### ", 5)
    part = part[:nxt] if nxt > 0 else part
    part = part[:part.find("\n---")] if "\n---" in part else part
    found = re.findall(r"`([^`]+)`", part)
    words = re.search(r"(?:Keywords|Ключевые слова): (.+?)\.\s*$", part.replace("\n", " "), re.S)
    return found + ([x.strip() for x in words.group(1).split(",")] if words else [])


def numbers(text):
    return sorted({int(n) for n in re.findall(r"(?<![A-Za-z0-9.])(\d{1,4})(?![A-Za-z0-9.])", re.sub(r"\(\d+/80[^)]*\)", "", text)) if 1 < int(n) < 1000})


def truth():
    districts = len(re.findall(r"&\"\w+\"", re.search(r"const DISTRICTS: Array\[StringName\] = \[(.*?)\]", read("scripts/world/district_scene_factory.gd"), re.S).group(1)))
    ach = len(re.findall(r'^\t"(ach_\w+)": \{', read("scripts/systems/achievements_manager.gd"), re.M))
    endings = len(re.findall(r'^\t"(\w+)":\s+\{"title"', read("scripts/systems/endings_manager.gd"), re.M))
    daily = json.loads(read("content/daily_challenges.json"))["templates"]
    music = read("scripts/systems/music_manager.gd")
    layers = re.findall(r'^\t"(\w+)":', music[music.index("const LAYERS"):music.index("}", music.index("const LAYERS"))], re.M)
    return {"districts": districts, "monsters": len(list((ROOT / "data" / "monsters").glob("monster_*.tres"))), "endings": endings, "languages": len(list((ROOT / "data" / "i18n").glob("*.json"))),
            "achievements": ach, "daily": len(daily), "music layers": len([x for x in layers if x not in ("rain", "wind")])}


def findings(data, facts):
    out = []
    en_numbers = numbers(data["en"]["short"] + "\n" + data["en"]["full"])
    for loc, d in data.items():
        if len(d["title"]) > TITLE_MAX:
            out.append("L1 %s: the title is %d characters (limit %d)" % (loc, len(d["title"]), TITLE_MAX))
        if len(d["short"]) > SHORT_MAX:
            out.append("L2 %s: the short description is %d characters (limit %d)" % (loc, len(d["short"]), SHORT_MAX))
        if d["short_declared"] != len(d["short"]):
            out.append("L2 %s: the listing declares %d characters, the text has %d" % (loc, d["short_declared"], len(d["short"])))
        if len(d["full"]) > FULL_MAX:
            out.append("L3 %s: the full description is %d characters (limit %d)" % (loc, len(d["full"]), FULL_MAX))
        if loc != "en" and numbers(d["short"] + "\n" + d["full"]) != en_numbers:
            out.append("L4 %s: the numbers %s differ from the English %s" % (loc, numbers(d["short"] + "\n" + d["full"]), en_numbers))
    claims = {"districts": r"(\d+) connected districts", "monsters": r"(\d+) enemy types", "endings": r"(\d+) endings", "languages": r"(\d+) fully localized languages",
              "achievements": r"(\d+) achievements", "daily": r"(\d+) daily challenges", "music layers": r"(\d+)-layer adaptive"}
    en_text = data["en"]["short"] + "\n" + data["en"]["full"]
    for key, rx in claims.items():
        m = re.search(rx, en_text)
        if m is None:
            out.append("L5 en: no claim of %s found" % key)
        elif int(m.group(1)) != facts[key]:
            out.append("L5 en: the text says %s %s, the code holds %d" % (m.group(1), key, facts[key]))
    for name, (rel, rx) in FEATURES.items():
        if name.lower() in en_text.lower() and not re.search(rx, read(rel)):
            out.append("L6 en: the text names %r and %s does not hold %r" % (name, rel, rx))
    menu = {loc: json.loads(read("data/i18n/%s.json" % loc))["menu_title"] for loc in LOCALES}
    for loc, d in data.items():
        if d["title"].casefold() != menu[loc].casefold():
            out.append("L7 %s: the store title %r is not the in-game title %r" % (loc, d["title"], menu[loc]))
    return out


def aso(d):
    text = (d["short"] + "\n" + d["full"]).casefold()
    hit = [t for t in d["tags"] if t.casefold() in text]
    words = max(1, len(text.split()))
    return len(hit), len(d["tags"]), 100.0 * sum(text.count(t.casefold()) for t in d["tags"]) / words


def write(path, data, facts, bad):
    lines = ["# Store listing audit (Session 23)", "",
             "Generated by `python tools/qa_sim/listing_audit.py --write store/LISTING_AUDIT.md`; the same tool is a static gate of `tools/check.sh`. Source: `store/listing.md`. Limits: title %d, short description %d, full description %d characters." % (TITLE_MAX, SHORT_MAX, FULL_MAX), "",
             "| Locale | Title | Short | Full | Numbers | Tags in the text | Tag mentions per 100 words |", "|---|---|---|---|---|---|---|"]
    for loc in LOCALES:
        d = data[loc]
        hit, total, density = aso(d)
        lines.append("| %s | %d | %d | %d | %s | %d of %d | %.1f |" % (loc, len(d["title"]), len(d["short"]), len(d["full"]), ", ".join(str(n) for n in numbers(d["short"] + "\n" + d["full"])), hit, total, density))
    lines += ["", "What the code holds (the numbers the English text claims): " + "; ".join("%s %d" % (k, v) for k, v in facts.items()) + ".",
              "Claims of features checked in the scripts: " + ", ".join(FEATURES) + ".",
              "Words per 100 are counted on spaces: for Japanese, Chinese and Arabic text the column is a rough count and is not a target.", "",
              "Findings: %s." % ("none" if not bad else "; ".join(bad))]
    pathlib.Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv):
    if "--demo" in argv:
        assert numbers("11 districts, 30 daily (70/80 chars) 5-layer 30日") == [5, 11, 30]
        d = {"en": {"title": "x" * 31, "short": "s" * 81, "short_declared": 80, "full": "11 a", "tags": []}, "ru": {"title": "x", "short": "s", "short_declared": 1, "full": "12 a", "tags": []}}
        bad = findings(d, {"districts": 11, "monsters": 12, "endings": 5, "languages": 13, "achievements": 31, "daily": 60, "music layers": 5})
        assert any(b.startswith("L1") for b in bad) and any(b.startswith("L2") for b in bad) and any(b.startswith("L4") for b in bad)
        print("listing_audit demo: a long title, a long short text and a number that differs are all found")
        return 0
    data = parse(LISTING.read_text(encoding="utf-8").replace("\r\n", "\n"))
    facts = truth()
    bad = findings(data, facts)
    for line in bad:
        print("FAIL", line)
    if "--write" in argv:
        write(argv[argv.index("--write") + 1], data, facts, bad)
    print("listing_audit: %d locale(s), %d finding(s)" % (len(data), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
