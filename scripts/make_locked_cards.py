#!/usr/bin/env python3
"""Deterministic generator for the seven new district card _locked variants.

Spec: docs/LEDGER_ARTFINAL.md L86/L93 — locked = same scene, desaturated
~60%, darkened, faint fog overlay, grain; NO flat silhouette, NO lock glyph.

Implementation: the exact transform is recovered by an OLS fit over the four
untouched keeper pairs (suburbs, residential, industrial, power_station) in
assets/textures/cards/:

    locked_interior = A @ unlocked_interior + t     (per-pixel RGB affine)

The fit refits itself from disk on every run (the keepers are frozen, so it
is stable across runs — verify with two runs: byte-identical output).
Measured fit residual on the keeper pairs: ~2.5/255 white noise (the grain
the keeper locked cards carry), so the same grain class
(regen_cards_v2.add_grain) is re-applied at the measured amplitude (0.01)
with the per-district stable seed (base 13, as in the master pipeline).

Per district (input: content/cards/twins/card_<d>_512.png):
  interior [4:508]^2 : A @ u + t -> grain -> clamp [16,240] -> round
  border   4px       : flat round(accent * 0.6)
    (keeper locked borders are flat — measured std 0.0 — and exactly
     round(accent*0.6))
Output: assets/textures/cards/card_<d>_locked_512.png (replaces the old
duplicate-photo locked variants).

Verification (exit 1 on any FAIL): 512^2 exact, "0 pure" (16<=v<=240),
interior not flat (per-channel std > 4 => the scene survives, not a
silhouette), border flat (std 0).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
from regen_cards_v2 import add_grain, stable_seed  # noqa: E402

ASSETS = REPO_ROOT / "assets" / "textures" / "cards"
TWIN_DIR = REPO_ROOT / "content" / "cards" / "twins"
KEEPERS = ["suburbs", "residential", "industrial", "power_station"]
NEW = ["gas_station", "hospital", "park", "police", "school", "substation", "warehouses"]
BORDER = 4
FIT_MARGIN = 6        # fit region [6:506]^2 (safe off the border)
GRAIN_AMP = 0.01      # measured from the keeper-locked residual (~2.5/255)
SEED_BASE = 13        # same base seed as the master pipeline
CLAMP = (16, 240)     # project "0 pure" convention


def load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB")).astype(np.float64)


def fit_transform() -> tuple[np.ndarray, np.ndarray]:
    """OLS-fit the keeper locked = A @ unlocked + t over the 4 keeper pairs."""
    Us, Ls = [], []
    for d in KEEPERS:
        u = load(ASSETS / f"card_{d}_512.png")
        l = load(ASSETS / f"card_{d}_locked_512.png")
        m = slice(FIT_MARGIN, 512 - FIT_MARGIN)
        Us.append(u[m, m].reshape(-1, 3))
        Ls.append(l[m, m].reshape(-1, 3))
    U = np.vstack(Us)
    L = np.vstack(Ls)
    F = np.column_stack([U, np.ones(len(U))])
    M, *_ = np.linalg.lstsq(F, L, rcond=None)
    return M[:3].T.copy(), M[3].copy()


def check_border(a: np.ndarray) -> np.ndarray:
    corner = a[0, 0]
    ring = np.concatenate([
        a[:BORDER].reshape(-1, 3), a[-BORDER:].reshape(-1, 3),
        a[:, :BORDER].reshape(-1, 3), a[:, -BORDER:].reshape(-1, 3),
    ])
    if ring.std(0).max() > 3.0 or np.abs(ring.mean(0) - corner).max() > 3.0:
        raise SystemExit(
            f"border is not a flat 4px accent (std {ring.std(0).round(2)})")
    return corner


def main() -> int:
    A, t = fit_transform()
    print(f"fit A =\n{np.round(A, 4)}\n  t = {np.round(t, 2)}")
    ok = True
    for d in NEW:
        u = load(TWIN_DIR / f"card_{d}_512.png")
        if u.shape != (512, 512, 3):
            print(f"FAIL {d}: dims {u.shape}")
            ok = False
            continue
        accent = check_border(u)
        interior = u[BORDER:512 - BORDER, BORDER:512 - BORDER]
        v = interior @ A.T + t
        v = add_grain(v, GRAIN_AMP, stable_seed(SEED_BASE, d))
        v = np.clip(v, *CLAMP).round().astype(np.uint8)
        out = np.empty((512, 512, 3), np.uint8)
        out[BORDER:512 - BORDER, BORDER:512 - BORDER] = v
        bc = np.round(accent * 0.6).astype(np.uint8)
        out[:BORDER, :] = bc
        out[-BORDER:, :] = bc
        out[:, :BORDER] = bc
        out[:, -BORDER:] = bc

        o = out.astype(np.float64)
        inter = o[BORDER:512 - BORDER, BORDER:512 - BORDER].reshape(-1, 3)
        pstd = inter.std(0)  # per-channel global std
        checks = {
            "dims": o.shape == (512, 512, 3),
            "0 pure": o.min() >= CLAMP[0] and o.max() <= CLAMP[1],
            "not flat": bool(pstd.min() > 4.0),
        }
        Image.fromarray(out).save(ASSETS / f"card_{d}_locked_512.png")
        status = "PASS" if all(checks.values()) else "FAIL"
        print(f"{status} {d:14s} min={o.min():.0f} max={o.max():.0f} "
              f"chan_std={pstd.round(1)} {checks}")
        ok = ok and all(checks.values())
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
