#!/usr/bin/env python3
"""
audit_card_clusters.py — re-run the card-cluster audit (docs/KNOWN_ISSUES.md,
docs/artifacts/visual-consistency/visual_consistency_report.md section 4).

Compares the 11 district card images (4 keeper cards + 7 new twins) with
aHash (8x8) Hamming distance and mean-absolute-difference on 32x32 greyscale,
all C(11,2)=55 pairs, plus k-means (k=11) on a small feature vector to count
distinct clusters.

Target: 11/11 distinct — every pair Hamming >= 8 (the historical
cross-cluster floor) — and k-means yields 11 singleton clusters.

Usage (repo root, needs pillow+numpy):
  .venv/bin/python scripts/audit_card_clusters.py
Optional: --images PATH ... to audit an explicit set.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    sys.exit(f"audit_card_clusters.py needs pillow+numpy ({exc})")

REPO_ROOT = Path(__file__).resolve().parent.parent
KEEPERS = ("suburbs", "residential", "industrial", "power_station")
NEW = ("park", "school", "hospital", "gas_station", "police",
       "warehouses", "substation")


def default_images() -> list[tuple[str, Path]]:
    imgs = []
    for d in KEEPERS:
        imgs.append((f"keeper_{d}", REPO_ROOT / "assets/textures/cards/card_"
                     f"{d}_512.png"))
    for d in NEW:
        imgs.append((f"new_{d}", REPO_ROOT / "content/cards/twins/card_"
                     f"{d}_512.png"))
    return imgs


def feats(path: Path) -> dict:
    im = Image.open(path).convert("RGB")
    g = np.asarray(im.convert("L").resize((32, 32)), dtype=np.float64)
    rgb = np.asarray(im, dtype=np.float64).reshape(-1, 3)
    a = np.asarray(im.convert("L").resize((8, 8)), dtype=np.float64)
    h = (a > a.mean()).astype(np.uint8)
    # feature vector: 32x32 grey + per-channel means/stds + 3x3 colour block
    blocks = np.asarray(im.convert("L").resize((3, 3)), dtype=np.float64).ravel()
    vec = np.concatenate([g.ravel(), rgb.mean(0), rgb.std(0), blocks])
    return {"grey32": g, "hash": h, "vec": vec}


def hamming(a: np.ndarray, b: np.ndarray) -> int:
    return int((a != b).sum())


def kmeans(vecs: np.ndarray, k: int, iters: int = 40, seed: int = 7) -> np.ndarray:
    rng = np.random.default_rng(seed)
    c = vecs[rng.choice(len(vecs), k, replace=False)].copy()
    lab = np.zeros(len(vecs), dtype=int)
    for _ in range(iters):
        d = ((vecs[:, None, :] - c[None, :, :]) ** 2).sum(-1)
        lab = d.argmin(1)
        for j in range(k):
            m = lab == j
            if m.any():
                c[j] = vecs[m].mean(0)
    return lab


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--images", nargs="*", default=None)
    args = ap.parse_args()

    if args.images:
        pairs = [(Path(p).stem, Path(p)) for p in args.images]
    else:
        pairs = default_images()
    missing = [str(p) for _, p in pairs if not p.exists()]
    if missing:
        sys.exit("missing images: " + ", ".join(missing))

    F = {name: feats(p) for name, p in pairs}
    names = list(F)
    print(f"card-cluster audit — {len(names)} images, {len(names)*(len(names)-1)//2} pairs")
    print("names: " + ", ".join(names) + "\n")

    # Pre-existing keeper twin: the shipped suburbs and residential cards are
    # both graded hero_first_restore (LEDGER_ARTFINAL L4) — a known defect
    # frozen in place because the keeper cards may not be modified. Reported,
    # excluded from the distinctness gate. Recognized in both naming
    # conventions: keeper_* (content/cards baseline) and card_*_512 (shipped
    # assets).
    PREEXISTING_PAIRS = (
        frozenset({"keeper_suburbs", "keeper_residential"}),
        frozenset({"card_suburbs_512", "card_residential_512"}),
    )
    def is_preexisting(a: str, b: str) -> bool:
        return frozenset((a, b)) in PREEXISTING_PAIRS

    worst_h, worst_m, worst_pair = 99, 999.0, None
    rows = []
    preexisting = []
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a, b = names[i], names[j]
            h = hamming(F[a]["hash"], F[b]["hash"])
            m = float(np.mean(np.abs(F[a]["grey32"] - F[b]["grey32"])))
            rows.append((h, m, a, b))
            if is_preexisting(a, b):
                preexisting.append((h, m, a, b))
                continue
            if h < worst_h or (h == worst_h and m < worst_m):
                worst_h, worst_m, worst_pair = h, m, (a, b)
    rows.sort()
    print("12 closest pairs (hamming, mad32):")
    for h, m, a, b in rows[:12]:
        flag = "PRE " if is_preexisting(a, b) else ("OK " if h >= 8 else "FAIL")
        print(f"  {flag} h={h:2d} mad={m:5.2f}  {a} / {b}")
    print(f"\nworst pair (excluding pre-existing twin): "
          f"h={worst_h} mad={worst_m:.2f} ({worst_pair[0]} / {worst_pair[1]})")
    for h, m, a, b in preexisting:
        print(f"pre-existing keeper twin (frozen, out of scope): "
              f"h={h} mad={m:.2f} ({a} / {b}) — both ship hero_first_restore")

    vecs = np.stack([F[n]["vec"] for n in names])
    lab = kmeans(vecs, 11)
    sizes = sorted((int((lab == k).sum()) for k in range(11)), reverse=True)
    clusters = {}
    for n, l in zip(names, lab):
        clusters.setdefault(int(l), []).append(n)
    multi = {k: v for k, v in clusters.items() if len(v) > 1}
    print(f"\nk-means (k=11) cluster sizes: {sizes}")
    if multi:
        print("non-singleton clusters:")
        for k, v in sorted(multi.items()):
            print(f"  cluster {k}: {v}")

    ok = worst_h >= 8 and not multi
    if ok:
        detail = (f"all 7 new cards distinct from each other and from all keepers "
                  f"(min cross Hamming {worst_h} >= 8), k-means 11 singletons; "
                  "suburbs/residential keeper twin pre-existing and frozen")
    else:
        detail = "see failures above"
    print(f"\nAUDIT {'PASS' if ok else 'FAIL'}: {detail}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
