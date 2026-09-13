#!/usr/bin/env python3
"""Cross-consistency auditor for content/** (CONTENT DEPTH pass).

Zone: content/** EXCEPT content/daily* and content/ngp*.

Checks, in order:
  A. id uniqueness  - note ids, fixed-spawn ids, world-bible ids, secret ids,
                      per-district zone ids
  B. ref resolution - world_refs / refs / members / faction_refs / author /
                      speaker / first_mention.note / item ids / item_type /
                      fixed_spawn.zone / location_hint zone hints / i18n keys
  C. gate legality  - GDD 12.3 act mapping, reveal min_stage range,
                      Act II/III facts not revealed before their gate,
                      world_refs reachability closure (README contract)
  D. i18n canon     - every content i18n key exists in data/i18n/en.json and
                      its value matches the content `en` source verbatim
  E. orphan keys    - en.json LORE_/WORLD_ keys with no backing content entry
  F. PVC claims     - docs/PLAYER_VISIBLE_CHANGES.md lore-note counts per district

Exit code 0 = 0 defects. Every defect prints as:
  <SEV> <CODE> <where> :: <detail>
"""

import json
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

# ---- canon -----------------------------------------------------------------

# GDD 4.1 fixed restore order -> district index (1-based)
CHAIN = [
    "suburbs", "residential", "park", "school", "hospital", "gas_station",
    "police", "warehouses", "industrial", "substation", "power_station",
]

# GDD 12.3: Act I = D1-3, Act II = D4-8, Act III = D9-11
def act_of_district(d):
    i = CHAIN.index(d) + 1
    if i <= 3:
        return 1
    if i <= 8:
        return 2
    return 3

# powered_by, read from data/districts/district_<id>.tres (live data)
def load_powered_by():
    pb = {}
    for d in CHAIN:
        p = os.path.join(ROOT, "data", "districts", "district_%s.tres" % d)
        m = re.search(r"powered_by\s*=\s*\[(.*?)\]", open(p, encoding="utf-8").read())
        pb[d] = re.findall(r'&"([^"]+)"', m.group(1)) if m else []
    return pb

POWERED_BY = load_powered_by()

def guaranteed_closure(d):
    """Transitive powered_by closure = districts guaranteed FULL before d opens."""
    out, stack = set(), list(POWERED_BY.get(d, []))
    while stack:
        p = stack.pop()
        if p in out:
            continue
        out.add(p)
        stack.extend(POWERED_BY.get(p, []))
    return out

STAGE_NAMES = ["DARK", "PARTIAL", "STREETS", "FULL"]
STAGE_RANK = {n: i for i, n in enumerate(STAGE_NAMES)}

# GDD 12.3 / world bible rule 3: the Project Architect reveal gate
ARCHITECT_GATE = ("hospital", 2)  # hospital STREETS

# item_type must be one of these AND must exist as data/items/<t>.tres
NOTE_ITEM_TYPES = ["document", "photo", "audio_log"]

EXCLUDED_PREFIXES = ("content/daily", "content/ngp")

# ---- helpers ---------------------------------------------------------------

def rel(p):
    return os.path.relpath(p, ROOT).replace(os.sep, "/")

def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)

class Audit:
    def __init__(self):
        self.defects = []

    def add(self, sev, code, where, detail):
        self.defects.append((sev, code, where, detail))

    def err(self, code, where, detail):
        self.add("ERROR", code, where, detail)

    def warn(self, code, where, detail):
        self.add("WARN", code, where, detail)

    def info(self, code, where, detail):
        self.add("INFO", code, where, detail)

    def report(self):
        order = {"ERROR": 0, "WARN": 1, "INFO": 2}
        for sev, code, where, detail in sorted(self.defects, key=lambda d: (order[d[0]], d[1], d[2])):
            print("%-5s %-26s %s :: %s" % (sev, code, where, detail))
        e = sum(1 for d in self.defects if d[0] == "ERROR")
        w = sum(1 for d in self.defects if d[0] == "WARN")
        i = sum(1 for d in self.defects if d[0] == "INFO")
        print("\n== %d ERROR, %d WARN, %d INFO ==" % (e, w, i))
        return 1 if e else 0


# ---- gather ----------------------------------------------------------------

def content_jsons():
    out = []
    for base, dirs, files in os.walk(os.path.join(ROOT, "content")):
        for fn in sorted(files):
            if not fn.endswith(".json"):
                continue
            full = os.path.join(base, fn)
            r = rel(full)
            if r.startswith(EXCLUDED_PREFIXES):
                continue
            out.append(full)
    return sorted(out)


def main():
    A = Audit()

    en = load(os.path.join(ROOT, "data", "i18n", "en.json"))

    items = set()
    idir = os.path.join(ROOT, "data", "items")
    for fn in os.listdir(idir):
        if fn.endswith(".tres"):
            txt = open(os.path.join(idir, fn), encoding="utf-8").read()
            m = re.search(r'^id\s*=\s*&"([^"]+)"', txt, re.M)
            items.add(m.group(1) if m else fn[:-5])

    packs = {}          # district -> lore_notes dict
    spawns = {}         # district -> item_spawns dict
    world = {}          # file -> dict

    for p in content_jsons():
        r = rel(p)
        d = load(p)
        if r.startswith("content/districts/"):
            dist = r.split("/")[2]
            if r.endswith("lore_notes.json"):
                packs[dist] = (p, d)
            elif r.endswith("item_spawns.json"):
                spawns[dist] = (p, d)
        else:
            world[r] = (p, d)

    # -- collect every world-bible id and its reveal ------------------------
    world_ids = {}      # id -> (file, reveal_dict_or_None, act_or_None)
    WORLD_KEYMAP = {
        "content/world/characters.json": "characters",
        "content/world/factions.json": "factions",
        "content/world/history.json": "events",
        "content/world/radio_transcripts.json": "transcripts",
        "content/lore/diary_entries.json": "entries",
        "content/lore/news_clippings.json": "clippings",
    }

    def note_id(where, _id, kind):
        if _id in world_ids:
            A.err("DUP_ID", where, "'%s' already defined in %s" % (_id, world_ids[_id][0]))
        world_ids[_id] = (where, None, None)

    for r, key in WORLD_KEYMAP.items():
        if r not in world:
            A.err("MISSING_FILE", r, "world-bible file absent")
            continue
        p, d = world[r]
        for e in d.get(key, []):
            _id = e.get("id")
            if not _id:
                A.err("MISSING_ID", r, "entry without id: %r" % (e,))
                continue
            if _id in world_ids:
                A.err("DUP_ID", r, "'%s' duplicates definition in %s" % (_id, world_ids[_id][0]))
            world_ids[_id] = (r, e.get("reveal"), e.get("act"))
        A.info("COUNT", r, "%s = %d" % (key, len(d.get(key, []))))

    # world-bible count contract (docs/CONTENT_WORLD_BIBLE.md table)
    EXPECT = {"content/world/characters.json": 9, "content/world/factions.json": 5,
              "content/world/history.json": 11, "content/world/radio_transcripts.json": 3,
              "content/lore/diary_entries.json": 4, "content/lore/news_clippings.json": 5}
    for r, n in EXPECT.items():
        if r in world:
            key = WORLD_KEYMAP[r]
            got = len(world[r][1].get(key, []))
            if got != n:
                A.err("BIBLE_COUNT", r, "world bible documents %d, file has %d" % (n, got))

    # -- i18n key inventory contract (52 keys) ------------------------------
    # characters 9*2 + factions 5*2 + radio 3*2 + diary 4*2 + news 5*2 = 52

    # -- A/B/C/D over district packs ----------------------------------------
    all_note_ids = {}
    for dist in sorted(packs):
        p, d = packs[dist]
        r = rel(p)
        if d.get("district") != dist:
            A.err("DISTRICT_MISMATCH", r, "'district' field is %r, folder is %r" % (d.get("district"), dist))
        if dist not in CHAIN:
            A.err("UNKNOWN_DISTRICT", r, "'%s' not in GDD 4.1 chain" % dist)
            continue

        sp = spawns.get(dist)
        zones = set()
        if sp:
            zones = set(sp[1].get("zones", []) or [])

        seen_zones_here = set()
        for n in d.get("notes", []):
            _id = n.get("id", "<no id>")
            where = "%s#%s" % (r, _id)

            # A. uniqueness + naming contract <district>_note_NN
            if _id in all_note_ids:
                A.err("DUP_NOTE_ID", where, "duplicate note id (also in %s)" % all_note_ids[_id])
            all_note_ids[_id] = r
            if not re.fullmatch(r"%s_note_\d\d" % re.escape(dist), _id):
                A.err("NOTE_ID_FORMAT", where, "violates contract '<district>_note_NN'")

            # item_type
            it = n.get("item_type")
            if it not in NOTE_ITEM_TYPES:
                A.err("BAD_ITEM_TYPE", where, "item_type %r not in %s" % (it, NOTE_ITEM_TYPES))
            elif it not in items:
                A.err("ITEM_TYPE_NOT_AN_ITEM", where, "'%s' has no data/items/%s.tres" % (it, it))

            # B. i18n keys exist in en
            i18n = n.get("i18n_keys", {})
            for slot in ("title", "text"):
                k = i18n.get(slot)
                if not k:
                    A.err("MISSING_I18N_KEY", where, "no i18n_keys.%s" % slot)
                    continue
                if k not in en:
                    A.err("I18N_KEY_ABSENT", where, "%s not in data/i18n/en.json" % k)
                else:
                    src = (n.get("en") or {}).get(slot)
                    if src is None:
                        A.err("NO_EN_SOURCE", where, "i18n key %s but no en.%s source" % (k, slot))
                    elif en[k] != src:
                        A.err("I18N_CANON_SLIP", where,
                              "en.json %s differs from content en.%s\n      en.json : %r\n      content : %r"
                              % (k, slot, en[k], src))
                # key naming contract
                m = re.fullmatch(r"LORE_%s_(\d\d)_%s" % (dist.upper(), slot.upper()), k or "")
                if not m:
                    A.err("I18N_KEY_FORMAT", where, "'%s' violates LORE_<DISTRICT>_<NN>_%s" % (k, slot.upper()))
                elif _id.endswith("_note_" + m.group(1)) is False:
                    A.err("I18N_KEY_INDEX", where, "key index %s does not match note id %s" % (m.group(1), _id))

            # C. min_stage range
            ms = n.get("min_stage")
            if not isinstance(ms, int) or not (0 <= ms <= 3):
                A.err("BAD_MIN_STAGE", where, "min_stage %r not an int 0..3" % (ms,))

            # B. world_refs resolve + C. reachability
            allowed = guaranteed_closure(dist) | {dist}
            for ref in n.get("world_refs", []) or []:
                if ref not in world_ids:
                    A.err("DEAD_WORLD_REF", where, "'%s' resolves to nothing" % ref)
                    continue
                rfile, reveal, _act = world_ids[ref]
                if reveal is None:
                    continue
                rd = reveal.get("district")
                rms = reveal.get("min_stage", 0)
                if rd not in allowed:
                    A.err("REF_UNREACHABLE", where,
                          "'%s' reveals at %s but %s only guarantees {%s}"
                          % (ref, rd, dist, ", ".join(sorted(allowed - {dist})) or "nothing"))
                elif rd == dist and isinstance(ms, int) and ms < rms:
                    A.err("REF_GATE_MISMATCH", where,
                          "'%s' reveals at %s min_stage %d but note appears at min_stage %d"
                          % (ref, rd, rms, ms))

            # B. location_hint zone mentions must exist in this district
            hint = n.get("location_hint", "") or ""
            for z in re.findall(r"\((z_[a-z0-9_]+)\)", hint):
                if zones and z not in zones:
                    A.err("DEAD_ZONE_HINT", where, "hint names %s, absent from item_spawns zones %s"
                          % (z, sorted(zones)))
                seen_zones_here.add(z)

        A.info("COUNT", r, "notes = %d" % len(d.get("notes", [])))

    # -- item_spawns checks --------------------------------------------------
    for dist in sorted(spawns):
        p, d = spawns[dist]
        r = rel(p)
        if d.get("district") != dist:
            A.err("DISTRICT_MISMATCH", r, "'district' field is %r, folder is %r" % (d.get("district"), dist))
        zones = d.get("zones", []) or []
        if len(set(zones)) != len(zones):
            dupes = sorted({z for z in zones if zones.count(z) > 1})
            A.err("DUP_ZONE_ID", r, "duplicate zone ids: %s" % dupes)

        t = d.get("tables", {})
        for stage in STAGE_NAMES:
            if stage not in t:
                A.err("MISSING_STAGE_TABLE", r, "no tables.%s (DistrictData.Stage)" % stage)
        for stage, rows in t.items():
            if stage not in STAGE_RANK:
                A.err("UNKNOWN_STAGE", r, "tables key %r is not a DistrictData.Stage" % stage)
                continue
            for row in rows:
                if row.get("item") not in items:
                    A.err("DEAD_ITEM_ID", "%s#%s" % (r, stage),
                          "item '%s' has no data/items/*.tres" % row.get("item"))
                if not isinstance(row.get("weight"), (int, float)) or row.get("weight", 0) <= 0:
                    A.err("BAD_WEIGHT", "%s#%s" % (r, stage), "weight %r not > 0" % row.get("weight"))
                lo, hi = row.get("min"), row.get("max")
                if not (isinstance(lo, int) and isinstance(hi, int) and 1 <= lo <= hi):
                    A.err("BAD_QTY_RANGE", "%s#%s" % (r, stage), "min/max %r/%r not 1<=min<=max" % (lo, hi))

        fs_ids = set()
        for fx in d.get("fixed_spawns", []) or []:
            fid = fx.get("id", "<no id>")
            where = "%s#%s" % (r, fid)
            if fid in fs_ids:
                A.err("DUP_FIX_ID", where, "duplicate fixed-spawn id in same file")
            fs_ids.add(fid)
            if fid != "<no id>" and not re.fullmatch(r"%s_fix_[a-z0-9_]+_\d\d" % re.escape(dist), fid):
                A.err("FIX_ID_FORMAT", where, "violates contract '<district>_fix_<purpose>_NN'")
            if fx.get("item") not in items:
                A.err("DEAD_ITEM_ID", where, "item '%s' has no data/items/*.tres" % fx.get("item"))
            z = fx.get("zone")
            if zones and z not in zones:
                A.err("DEAD_ZONE_REF", where, "zone '%s' absent from this file's zones %s" % (z, sorted(zones)))
        A.info("COUNT", r, "fixed_spawns = %d, zones = %d" % (len(d.get("fixed_spawns") or []), len(zones)))

    # -- world-bible internal refs + gates ----------------------------------
    def check_refs(r, e, field, label):
        for ref in e.get(field, []) or []:
            if ref not in world_ids and not re.fullmatch(r"[a-z_]+_note_\d\d", ref):
                A.err("DEAD_REF", "%s#%s" % (r, e.get("id")), "%s '%s' resolves to nothing" % (label, ref))
            elif ref not in world_ids:
                if ref not in all_note_ids:
                    A.err("DEAD_NOTE_REF", "%s#%s" % (r, e.get("id")),
                          "%s '%s' matches no note id in any pack" % (label, ref))

    def check_i18n_entry(r, e, _id):
        i18n = e.get("i18n_keys", {})
        for slot in ("title", "text"):
            k = i18n.get(slot)
            if not k:
                A.err("MISSING_I18N_KEY", "%s#%s" % (r, _id), "no i18n_keys.%s" % slot)
                continue
            if k not in en:
                A.err("I18N_KEY_ABSENT", "%s#%s" % (r, _id), "%s not in en.json" % k)
            else:
                src = (e.get("en") or {}).get(slot)
                if src is None:
                    A.err("NO_EN_SOURCE", "%s#%s" % (r, _id), "key %s but no en.%s" % (k, slot))
                elif en[k] != src:
                    A.err("I18N_CANON_SLIP", "%s#%s" % (r, _id),
                          "en.json %s differs from content en.%s\n      en.json : %r\n      content : %r"
                          % (k, slot, en[k], src))

    for r, key in WORLD_KEYMAP.items():
        if r not in world:
            continue
        p, d = world[r]
        for e in d.get(key, []):
            _id = e.get("id")
            where = "%s#%s" % (r, _id)
            rv = e.get("reveal")
            if not rv:
                A.err("MISSING_REVEAL", where, "no reveal{} (world bible rule 2)")
            else:
                rd, rms = rv.get("district"), rv.get("min_stage")
                if rd not in CHAIN:
                    A.err("REVEAL_BAD_DISTRICT", where, "reveal.district %r not in GDD 4.1 chain" % rd)
                if not isinstance(rms, int) or not (0 <= rms <= 3):
                    A.err("BAD_MIN_STAGE", where, "reveal.min_stage %r not an int 0..3" % rms)
                # C. act gate legality (GDD 12.3).
                #
                # `act` means different things per file, so the rule is per-file:
                #   radio_transcripts.json -> act is DERIVED from reveal.district
                #     (CODE unlocks RADIO by reveal, so the two must agree).
                #   history.json -> act tracks the ERA the event happened in,
                #     per that file's own _contract ("era = when it HAPPENED").
                #     act 0 = pre-story (pre-blackout) and is legal regardless of
                #     where the player later learns it.
                act = e.get("act")
                if act is not None:
                    if not isinstance(act, int) or not (0 <= act <= 3):
                        A.err("BAD_ACT", where, "act %r not an int 0..3" % (act,))
                    elif r == "content/world/radio_transcripts.json":
                        want = act_of_district(rd) if rd in CHAIN else None
                        if want is not None and act != want:
                            A.err("ACT_GATE_MISMATCH", where,
                                  "act=%d but reveal.district %s is Act %d (GDD 12.3); "
                                  "in this file act is derived from reveal.district"
                                  % (act, rd, want))
                    elif act != 0 and rd in CHAIN:
                        # history.json: act describes era. A post-story event (act>=1)
                        # must not be revealed in an EARLIER act than the one it
                        # belongs to, which would leak later-act history early.
                        got = act_of_district(rd)
                        if got < act:
                            A.err("ACT_GATE_MISMATCH", where,
                                  "act=%d era event revealed in %s, an Act %d district (GDD 12.3)"
                                  % (act, rd, got))
                if act in (2, 3):
                    gd, gs = ARCHITECT_GATE
                    if rd in CHAIN:
                        cur = (CHAIN.index(rd), rms)
                        thr = (CHAIN.index(gd), gs)
                        if cur < thr:
                            A.err("ACT_REVEAL_TOO_EARLY", where,
                                  "Act %d fact revealed at %s stage %s, before the %s STREETS gate"
                                  % (act, rd, STAGE_NAMES[rms], gd))
            if r == "content/lore/diary_entries.json":
                if e.get("author") not in world_ids:
                    A.err("DEAD_REF", where, "author '%s' resolves to nothing" % e.get("author"))
            if r == "content/world/radio_transcripts.json":
                if e.get("speaker") not in world_ids:
                    A.err("DEAD_REF", where, "speaker '%s' resolves to nothing" % e.get("speaker"))
            if r == "content/world/factions.json":
                check_refs(r, e, "members", "member")
                for fd in e.get("districts", []) or []:
                    if fd not in CHAIN:
                        A.err("DEAD_DISTRICT_REF", where, "districts '%s' not in GDD 4.1 chain" % fd)
            if r in ("content/world/history.json",):
                check_refs(r, e, "refs", "ref")
            if r in ("content/lore/news_clippings.json",):
                check_refs(r, e, "faction_refs", "faction_ref")
            if "i18n_keys" in e:
                check_i18n_entry(r, e, _id)

    # characters.first_mention.note must resolve
    if "content/world/characters.json" in world:
        for e in world["content/world/characters.json"][1].get("characters", []):
            fm = e.get("first_mention")
            if fm:
                w = "%s#%s" % (rel(world["content/world/characters.json"][0]), e.get("id"))
                if fm.get("note") not in all_note_ids:
                    A.err("DEAD_NOTE_REF", w, "first_mention.note '%s' matches no note id" % fm.get("note"))
                if fm.get("district") not in CHAIN:
                    A.err("DEAD_DISTRICT_REF", w, "first_mention.district %r not in chain" % fm.get("district"))
                if fm.get("district") in CHAIN and fm.get("note") in all_note_ids:
                    owner = all_note_ids[fm["note"]].split("/")[2]
                    if owner != fm["district"]:
                        A.err("FIRST_MENTION_DISTRICT", w,
                              "note '%s' lives in %s, first_mention says %s" % (fm["note"], owner, fm["district"]))

    # -- secrets registry (content/secrets.json) -----------------------------
    used_keys_from_secrets = set()
    pending_locale_keys = []   # (key, en_source, secret_id) awaiting LOCALE handoff
    SECRET_THREADS = None
    spath = os.path.join(ROOT, "content", "secrets.json")
    if os.path.exists(spath):
        r = rel(spath)
        sd = load(spath)
        SECRET_THREADS = set((sd.get("_threads") or {}).keys())
        secs = sd.get("secrets", [])
        A.info("COUNT", r, "secrets = %d" % len(secs))
        if not (24 <= len(secs) <= 30):
            A.err("SECRETS_COUNT", r, "task requires 24-30 canon secrets, file has %d" % len(secs))
        sec_ids = set()
        for s in secs:
            sid = s.get("id", "<no id>")
            where = "%s#%s" % (r, sid)
            if sid in sec_ids:
                A.err("DUP_ID", where, "duplicate secret id")
            sec_ids.add(sid)
            if sid in world_ids or sid in all_note_ids:
                A.err("DUP_ID", where, "collides with a world-bible or note id")
            dist = s.get("district")
            if dist not in CHAIN:
                A.err("UNKNOWN_DISTRICT", where, "district %r not in GDD 4.1 chain" % dist)
                continue
            if not re.fullmatch(r"secret_%s_\d\d" % re.escape(dist), sid):
                A.err("SECRET_ID_FORMAT", where, "violates contract 'secret_<district>_NN'")
            # act derived from district
            want_act = act_of_district(dist)
            if s.get("act") != want_act:
                A.err("ACT_GATE_MISMATCH", where,
                      "act=%r but district %s is Act %d (GDD 12.3); act is derived" % (s.get("act"), dist, want_act))
            ms = s.get("min_stage")
            if not isinstance(ms, int) or not (0 <= ms <= 3):
                A.err("BAD_MIN_STAGE", where, "min_stage %r not an int 0..3" % (ms,))
            # zone must exist in that district's item_spawns zones
            zones = set(spawns[dist][1].get("zones", []) or []) if dist in spawns else set()
            z = s.get("zone")
            if not z:
                A.err("MISSING_ZONE", where, "no zone")
            elif zones and z not in zones:
                A.err("DEAD_ZONE_REF", where, "zone '%s' absent from %s item_spawns zones" % (z, dist))
            # reward
            rw = s.get("reward") or {}
            if rw.get("item") not in items:
                A.err("DEAD_ITEM_ID", where, "reward.item '%s' has no data/items/*.tres" % rw.get("item"))
            if not isinstance(rw.get("amount"), int) or rw.get("amount", 0) < 1:
                A.err("BAD_REWARD_QTY", where, "reward.amount %r not an int >= 1" % rw.get("amount"))
            # thread
            if SECRET_THREADS and s.get("thread") not in SECRET_THREADS:
                A.err("UNKNOWN_THREAD", where, "thread %r not declared in _threads" % s.get("thread"))
            # world_refs reachability
            allowed = guaranteed_closure(dist) | {dist}
            for ref in s.get("world_refs", []) or []:
                if ref not in world_ids:
                    A.err("DEAD_WORLD_REF", where, "'%s' resolves to nothing" % ref)
                    continue
                reveal = world_ids[ref][1]
                if reveal and reveal.get("district") not in allowed:
                    A.err("REF_UNREACHABLE", where,
                          "'%s' reveals at %s but %s only guarantees {%s}"
                          % (ref, reveal.get("district"), dist,
                             ", ".join(sorted(allowed - {dist})) or "nothing"))
            # i18n
            i18n = s.get("i18n_keys", {})
            for slot in ("title", "text"):
                k = i18n.get(slot)
                if not k:
                    A.err("MISSING_I18N_KEY", where, "no i18n_keys.%s" % slot)
                    continue
                m = re.fullmatch(r"SECRET_%s_(\d\d)_%s" % (dist.upper(), slot.upper()), k)
                if not m:
                    A.err("I18N_KEY_FORMAT", where, "'%s' violates SECRET_<DISTRICT>_<NN>_%s" % (k, slot.upper()))
                elif not sid.endswith("_" + m.group(1)):
                    A.err("I18N_KEY_INDEX", where, "key index %s does not match id %s" % (m.group(1), sid))
                if k not in en:
                    # Repo contract (content/README.md): CONTENT authors the `en`
                    # source; the LOCALE agent adds the keys to all 13 locales.
                    # A key authored in this pass and not yet handed off is
                    # PENDING, not a content defect. Pre-existing content (above)
                    # keeps the hard error.
                    pending_locale_keys.append((k, (s.get("en") or {}).get(slot), sid))
                    A.warn("I18N_KEY_PENDING", where,
                           "%s authored, awaiting LOCALE handoff to the 13 locales" % k)
                else:
                    src = (s.get("en") or {}).get(slot)
                    if src is None:
                        A.err("NO_EN_SOURCE", where, "key %s but no en.%s source" % (k, slot))
                    elif en[k] != src:
                        A.err("I18N_CANON_SLIP", where, "en.json %s differs from content en.%s" % (k, slot))
            used_keys_from_secrets.add(i18n.get("title"))
            used_keys_from_secrets.add(i18n.get("text"))
            # location_hint zone mentions
            for z2 in re.findall(r"\((z_[a-z0-9_]+)\)", s.get("location_hint", "") or ""):
                if zones and z2 not in zones:
                    A.err("DEAD_ZONE_HINT", where, "hint names %s, absent from %s zones" % (z2, dist))
    else:
        A.err("MISSING_FILE", "content/secrets.json", "secrets registry absent (TASK 2 deliverable)")

    # -- E. orphan i18n keys -------------------------------------------------
    used = set(used_keys_from_secrets)
    for r, key in WORLD_KEYMAP.items():
        if r in world:
            for e in world[r][1].get(key, []):
                used.update((e.get("i18n_keys") or {}).values())
    for dist, (p, d) in packs.items():
        for n in d.get("notes", []):
            used.update((n.get("i18n_keys") or {}).values())
    for k in sorted(en):
        if (k.startswith("LORE_") or k.startswith("WORLD_")) and k not in used:
            A.warn("ORPHAN_I18N_KEY", "data/i18n/en.json", "'%s' has no backing content entry" % k)
    pending_key_names = {k for k, _v, _s in pending_locale_keys}
    for k in sorted(used):
        if k and k not in en and k not in pending_key_names:
            A.err("I18N_KEY_ABSENT", "en.json", "content key '%s' missing from en.json" % k)

    # -- TASK 3: texts living ONLY in i18n ----------------------------------
    # A key is "i18n-only" when its text exists in data/i18n/*.json but is backed
    # by no content/** entry AND referenced by no script/scene. Those are prose
    # whose sole source of truth is a locale file, which breaks the repo rule that
    # content/** is the source of truth. Locales are NOT touched; the table goes
    # in the certificate for CODE to adopt.
    code_blob = []
    for base in ("scripts", "scenes", "components"):
        for dirpath, _dirs, files in os.walk(os.path.join(ROOT, base)):
            for fn in files:
                if fn.endswith((".gd", ".tscn", ".tres")):
                    try:
                        code_blob.append(open(os.path.join(dirpath, fn), encoding="utf-8").read())
                    except (OSError, UnicodeDecodeError):
                        pass
    code_blob = "\n".join(code_blob)
    i18n_only = []
    for k, v in en.items():
        if k in used:
            continue
        if k in code_blob:
            continue
        if not isinstance(v, str) or len(v.strip()) < 24:
            continue
        i18n_only.append((k, v))
    i18n_only.sort()
    A.info("I18N_ONLY_COUNT", "data/i18n/en.json",
           "%d keys hold prose backed by neither content/** nor any script/scene" % len(i18n_only))

    # -- artifacts: handoff tables ------------------------------------------
    adir = os.path.join(ROOT, "docs", "artifacts", "content-depth")
    os.makedirs(adir, exist_ok=True)

    if pending_locale_keys:
        with open(os.path.join(adir, "pending_locale_handoff.md"), "w", encoding="utf-8") as f:
            f.write("# Pending LOCALE handoff — content/secrets.json\n\n")
            f.write("Authored by CONTENT (this pass). `en` below is the source string;\n")
            f.write("the LOCALE agent adds these keys to all 13 locales. CONTENT never\n")
            f.write("edits `data/i18n/`. Source of truth: `content/secrets.json`.\n\n")
            f.write("| key | source (`en`) | secret id |\n|---|---|---|\n")
            for k, v, sid in sorted(pending_locale_keys):
                f.write("| `%s` | %s | `%s` |\n" % (k, json.dumps(v, ensure_ascii=False), sid))
            f.write("\nTotal: %d keys (%d secrets x 2).\n" % (len(pending_locale_keys), len(pending_locale_keys) // 2))

    with open(os.path.join(adir, "i18n_only_texts.md"), "w", encoding="utf-8") as f:
        f.write("# TASK 3 — texts living ONLY in i18n (CODE-sync table)\n\n")
        f.write("Keys whose prose exists in `data/i18n/*.json` but is backed by no\n")
        f.write("`content/**` entry and referenced by no script/scene. For these the\n")
        f.write("locale file is the only source of truth, which inverts the repo rule\n")
        f.write("that `content/**` is the source of truth for authored content.\n")
        f.write("**Locales were not touched.** Proposed `en` = current value verbatim;\n")
        f.write("CODE decides whether to adopt each into a content file or wire it.\n\n")
        def md_cell(s):
            """Escape a string for a markdown table cell (keys can hold \n and |)."""
            return (str(s).replace("\\", "\\\\").replace("|", "\\|")
                    .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t"))

        f.write("| key | proposed `en` |\n|---|---|\n")
        for k, v in i18n_only:
            f.write("| `%s` | %s |\n" % (md_cell(k), md_cell(v)))
        f.write("\nTotal: %d keys.\n" % len(i18n_only))
        f.write("\nVerified: none of these keys appears in any `.gd`, `.tscn` or\n")
        f.write("`.tres` under `scripts/`, `scenes/` or `components/`, and none is\n")
        f.write("backed by a `content/**` entry. They are dead or unadopted strings.\n")

    # -- F. PVC lore-note count claim ---------------------------------------
    pvc = os.path.join(ROOT, "docs", "PLAYER_VISIBLE_CHANGES.md")
    if os.path.exists(pvc):
        txt = open(pvc, encoding="utf-8").read()
        m = re.search(r"~12 pickups \+ its documents \+ (\d+) lore notes", txt)
        if m:
            claimed = int(m.group(1))
            counts = {d: len(packs[d][1].get("notes", [])) for d in packs}
            off = {d: c for d, c in counts.items() if c != claimed}
            if off:
                A.err("PVC_COUNT_SLIP", rel(pvc),
                      "claims %d lore notes per district, actual %s"
                      % (claimed, json.dumps(counts, sort_keys=True)))
            else:
                A.info("PVC_OK", rel(pvc), "claim '%d lore notes' matches all %d packs" % (claimed, len(counts)))

    # -- secrets framework reachability (feeds TASK 2 branch decision) -------
    secret_rooms = []
    sdir = os.path.join(ROOT, "scenes", "secrets")
    if os.path.isdir(sdir):
        secret_rooms = sorted(f for f in os.listdir(sdir) if f.endswith(".tscn"))
    empty = []
    for f in secret_rooms:
        txt = open(os.path.join(sdir, f), encoding="utf-8").read()
        if "secret.gd" not in txt and "secret_id" not in txt:
            empty.append(f)
    if empty:
        A.warn("SECRET_ROOM_STUB", "scenes/secrets/",
               "%d/%d secret_room_*.tscn contain no secret.gd/secret_id (unwired stubs)"
               % (len(empty), len(secret_rooms)))

    return A.report()


if __name__ == "__main__":
    sys.exit(main())
