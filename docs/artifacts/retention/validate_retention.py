#!/usr/bin/env python3
"""RETENTION CONTENT PASS v2 validator (VERIFY-AGENT).

Asserts, against repo HEAD:
  1. counts: 60 daily templates / 6 NG+ modifiers / 28 captions
  2. id uniqueness within each file
  3. NGP effects are float(bool-excluded)-only multipliers + bool-only toggles
  4. original-30 daily entries byte-equal to data/daily_challenges.json
     (modulo the list-separator comma on entry #30, which must gain one
     because the list continues in content/)
  5. new-type gating: photo_subject / no_flashlight_segment entries carry
     wired:false; photo entries require EventBus.photo_captured; wired
     types are NOT gated
  6. canon id whitelist: caption refs, gallery chain, daily/ngp id sets,
     title_key existence in data/i18n/en.json
  7. i18n: 100 new keys (60 DAILY_*_FLAVOR + 12 NGP_* + 28 CAPTION_*).
     NOTE: the brief's header says "110" but its own components sum to
     60+12+28=100; components win (council note in docs/CERT_RETENTION.md).
     Keys must be unique, carry en source, and NOT yet be in locales
     (CODE-sync pending).

Stdlib only. Exit 0 = ALL PASS. Run from repo root:
  python3 docs/artifacts/retention/validate_retention.py
"""
import json
import sys

ROOT = __file__.split("docs/artifacts/retention")[0] or "."
FAILURES: list[str] = []
PASSES: list[str] = []


def check(name: str, cond: bool, detail: str = "") -> None:
    (PASSES if cond else FAILURES).append(name if cond else f"{name} :: {detail}")


def load(path: str):
    with open(ROOT.rstrip("/") + "/" + path, encoding="utf-8") as f:
        return json.load(f)


def raw_lines_with(path: str, needle: str) -> list[str]:
    with open(ROOT.rstrip("/") + "/" + path, encoding="utf-8") as f:
        return [l for l in f.read().split("\n") if needle in l]


def main() -> int:
    daily = load("content/daily_challenges.json")
    orig = load("data/daily_challenges.json")
    ngp = load("content/ngp_modifiers.json")
    caps = load("content/captions.json")
    docs = load("data/documents.json")
    en = load("data/i18n/en.json")

    # ---- 1. counts ----
    check("daily-count-60", len(daily["templates"]) == 60, f"got {len(daily['templates'])}")
    check("ngp-count-6", len(ngp["modifiers"]) == 6, f"got {len(ngp['modifiers'])}")
    check("captions-count-28",
          len(caps["moments"]) == 12 and len(caps["gallery"]) == 16,
          f"got {len(caps['moments'])}+{len(caps['gallery'])}")

    # ---- 2. id uniqueness ----
    for label, ids in [
        ("daily", [t["id"] for t in daily["templates"]]),
        ("ngp", [m["id"] for m in ngp["modifiers"]]),
        ("captions", [c["id"] for c in caps["moments"]] + [c["id"] for c in caps["gallery"]]),
    ]:
        check(f"unique-{label}", len(set(ids)) == len(ids), f"dup in {ids}")

    # ---- 3. NGP float/bool-only effects ----
    for m in ngp["modifiers"]:
        e = m["effects"]
        check(f"ngp-{m['id']}-effect-keys", set(e) == {"multipliers", "toggles"}, str(sorted(e)))
        for k, v in e["multipliers"].items():
            check(f"ngp-{m['id']}-mult-{k}-float", type(v) is float, f"{k}={v!r}")
        for k, v in e["toggles"].items():
            check(f"ngp-{m['id']}-toggle-{k}-bool", type(v) is bool, f"{k}={v!r}")
    check("ngp-same-knob-multiply", ngp["stacking"]["same_knob"] == "multiply",
          str(ngp["stacking"]))
    check("ngp-gates", ngp["gates"] == "NG+≥1", str(ngp["gates"]))
    by_id = {m["id"]: m for m in ngp["modifiers"]}
    for m in ngp["modifiers"]:
        check(f"ngp-{m['id']}-gate", m["gate"] == "NG+≥1", str(m["gate"]))
        for x in m["exclusive_with"]:
            check(f"ngp-excl-{m['id']}-{x}-sym",
                  x in by_id and m["id"] in by_id[x]["exclusive_with"], f"{m['id']}->{x}")

    # ---- 4. original-30 byte-eq ----
    check("orig-still-30", len(orig["templates"]) == 30, f"got {len(orig['templates'])}")
    check("streak-preserved", daily["streak_rewards"] == orig["streak_rewards"] == [
        {"days": 7, "reward": 150}, {"days": 30, "reward": 750}, {"days": 100, "reward": 3000}],
        str(daily["streak_rewards"]))
    orig_entry_lines = raw_lines_with("data/daily_challenges.json", '"id":')
    got_entry_lines = raw_lines_with("content/daily_challenges.json", '"id":')[:30]
    check("byteeq-line-count", len(orig_entry_lines) == 30 and len(got_entry_lines) == 30,
          f"{len(orig_entry_lines)}/{len(got_entry_lines)}")
    mism = [i for i, (a, b) in enumerate(zip(orig_entry_lines, got_entry_lines))
            if a.strip().rstrip(",") != b.strip().rstrip(",")]
    check("byteeq-orig-30", not mism, f"lines differ at idx {mism}")
    for i, t in enumerate(daily["templates"][:30]):
        o = orig["templates"][i]
        check(f"byteeq-field-{o['id']}",
              {k: t[k] for k in ("id", "type", "target", "reward")} == o, str(t))

    # ---- 5. new-type wired:false gating ----
    WIRED_TYPES = {"kill_enemies", "find_secrets", "light_streets", "restore_districts", "play_minutes"}
    NEW_TYPES = {"photo_subject", "no_flashlight_segment"}
    check("daily-new-id-set",
          {t["id"] for t in daily["templates"][30:]} == {
              "kill_01", "kill_02", "kill_12", "kill_25", "kill_40",
              "secret_01", "secret_04", "secret_06", "secret_10", "secret_24",
              "streets_05", "streets_07", "streets_09", "streets_12", "streets_16",
              "restore_07", "restore_08", "restore_09", "restore_10", "restore_11",
              "play_30", "play_45", "play_60", "play_90", "play_120",
              "photo_01", "photo_03", "photo_05", "dark_05", "dark_10"},
          str(sorted(t["id"] for t in daily["templates"][30:])))
    for t in daily["templates"]:
        if t["type"] in NEW_TYPES:
            check(f"gate-{t['id']}-wired-false", t.get("wired") is False, str(t))
        else:
            check(f"gate-{t['id']}-wired-live",
                  t["type"] in WIRED_TYPES and t.get("wired", True) is not False, str(t))
    for t in daily["templates"]:
        if t["type"] == "photo_subject":
            check(f"gate-{t['id']}-requires-signal",
                  t.get("requires_signal") == "EventBus.photo_captured", str(t))

    # ---- 6. canon id whitelist ----
    check("ngp-id-set", set(by_id) == {
        "long_night", "whisper", "blackout_plus", "keepers_pact", "sprint", "ghost"},
        str(sorted(by_id)))
    KNOBS = {"battery", "hunter_hearing", "loot", "extra_dark_districts", "hints",
             "lore", "time_pressure", "cycle", "rewards", "crawlers_ignore", "achievements"}
    for m in ngp["modifiers"]:
        knobs = set(m["effects"]["multipliers"]) | set(m["effects"]["toggles"])
        check(f"ngp-{m['id']}-knobs-canon", knobs <= KNOBS, str(sorted(knobs)))
    ACH = {"first_light", "photographer", "overload"}
    END = {"light", "darkness"}
    SYS = {"ng_plus_activated"}
    kinds = [m["ref"]["kind"] for m in caps["moments"]]
    check("moments-kind-mix", sorted(kinds) == sorted(
        ["achievement"] * 3 + ["ending"] * 2 + ["system"] + ["lore_note"] * 6), str(kinds))
    for m in caps["moments"]:
        r = m["ref"]
        if r["kind"] == "achievement":
            check(f"canon-{m['id']}", r["id"] in ACH, str(r))
        elif r["kind"] == "ending":
            check(f"canon-{m['id']}", r["id"] in END, str(r))
        elif r["kind"] == "system":
            check(f"canon-{m['id']}", r["id"] in SYS, str(r))
        elif r["kind"] == "lore_note":
            check(f"canon-{m['id']}", r["id"] in docs, str(r))
        else:
            check(f"canon-{m['id']}", False, f"bad kind {r}")
    check("gallery-district-chain",
          [g["ref"]["id"] for g in caps["gallery"] if g["ref"]["kind"] == "district"] == [
              "suburbs", "residential", "park", "school", "hospital", "gas_station",
              "police", "warehouses", "industrial", "substation", "power_station"],
          "district chain/order drift")
    check("gallery-specials",
          [g["ref"]["id"] for g in caps["gallery"] if g["ref"]["kind"] == "special"] == [
              "night_zero", "the_keeper", "the_architect", "babka_lamp", "last_streetlight"],
          "specials drift")
    for g in caps["gallery"]:
        check(f"canon-{g['id']}-titlekey",
              g["title_key"] is None or g["title_key"] in en, str(g["title_key"]))

    # ---- 7. i18n: 110 keys, en source, not in locales ----
    daily_keys = [f"DAILY_{t['id'].upper()}_FLAVOR" for t in daily["templates"]]
    check("i18n-daily-60", len(daily_keys) == 60 and len(set(daily_keys)) == 60, "")
    for t in daily["templates"][30:]:
        check(f"i18n-{t['id']}-key", t.get("i18n_key") == f"DAILY_{t['id'].upper()}_FLAVOR",
              str(t.get("i18n_key")))
        check(f"i18n-{t['id']}-en", bool(t.get("en", {}).get("flavor", "").strip()), str(t))
    ngp_keys = [k for m in ngp["modifiers"] for k in m["i18n_keys"].values()]
    check("i18n-ngp-12", len(ngp_keys) == 12 and len(set(ngp_keys)) == 12
          and all(k.startswith("NGP_") for k in ngp_keys), str(ngp_keys))
    for m in ngp["modifiers"]:
        check(f"i18n-{m['id']}-en",
              bool(m["en"].get("name", "").strip()) and bool(m["en"].get("desc", "").strip()),
              str(m["en"]))
    cap_keys = [c["i18n_key"] for c in caps["moments"]] + [c["i18n_key"] for c in caps["gallery"]]
    check("i18n-caption-28", len(cap_keys) == 28 and len(set(cap_keys)) == 28
          and all(k.startswith("CAPTION_") for k in cap_keys), str(cap_keys))
    for c in caps["moments"] + caps["gallery"]:
        check(f"i18n-{c['id']}-en", bool(c["en"].get("text", "").strip()), str(c))
    all_keys = daily_keys + ngp_keys + cap_keys
    # Brief says "110" but itemizes 60+12+28=100; assert the itemized sum.
    check("i18n-total-100", len(all_keys) == 100 and len(set(all_keys)) == 100,
          f"got {len(all_keys)}/{len(set(all_keys))}")
    leaked = [k for k in all_keys if k in en]
    check("i18n-not-in-locales", not leaked, f"already in en.json: {leaked}")

    print(f"PASS {len(PASSES)} checks")
    for f in FAILURES:
        print("FAIL", f)
    print("RESULT:", "ALL PASS" if not FAILURES else f"{len(FAILURES)} FAILURES")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
