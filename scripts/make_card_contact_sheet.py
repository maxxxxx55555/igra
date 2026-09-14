#!/usr/bin/env python3
"""Rebuild docs/artifacts/art-final/cards_contact_sheet.png (deterministic).

Layout (recovered 2026-09-14 by cell-matching the pre-replacement sheet):
4 cols x 6 rows of 256^2 cells — cells 0-10 are the 11 districts' unlocked
cards, cells 11-21 their locked variants, cells 22-23 flat fill (#0c1016);
districts in alphabetical order. Each cell is the 512^2 card LANCZOS-resized
to 256^2, border included.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "assets" / "textures" / "cards"
OUT = REPO_ROOT / "docs" / "artifacts" / "art-final" / "cards_contact_sheet.png"
DISTRICTS = sorted([
    "suburbs", "residential", "industrial", "power_station", "park",
    "school", "hospital", "gas_station", "police", "warehouses", "substation",
])
FILL = np.array([12, 16, 22], np.uint8)


def main() -> int:
    if len(DISTRICTS) != 11:
        raise SystemExit("expected exactly 11 districts")
    sheet = np.zeros((6 * 256, 4 * 256, 3), np.uint8)
    for i, d in enumerate(DISTRICTS):
        for j, variant in enumerate(("", "_locked")):
            card = Image.open(ASSETS / f"card_{d}{variant}_512.png").convert("RGB")
            cell = card.resize((256, 256), Image.LANCZOS)
            r, c = divmod(i + 11 * j, 4)
            sheet[r * 256:(r + 1) * 256, c * 256:(c + 1) * 256] = cell
    sheet[5 * 256:, 3 * 256:] = FILL  # two empty cells
    Image.fromarray(sheet).save(OUT)
    print(f"wrote {OUT.relative_to(REPO_ROOT)} "
          f"({sheet.shape[1]}x{sheet.shape[0]}, 22 cards + 2 fill)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
