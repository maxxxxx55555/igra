#!/usr/bin/env python3
import subprocess, os
cards_dir = "assets/textures/cards"
target_cards = ["hospital", "school", "industrial", "gas_station"]

def regenerate_unlocked(district):
    inp = os.path.join(cards_dir, f"card_{district}_512.png")
    out = os.path.join(cards_dir, f"card_{district}_512.png")
    cmd = ["convert", inp,
        "-colorspace", "RGB",
        "-channel", "blue", "-evaluate", "multiply", "1.2", "+channel",
        "-channel", "green", "-evaluate", "multiply", "1.1", "+channel",
        "-channel", "red", "-evaluate", "multiply", "1.15", "+channel",
        "-auto-level", "-define", "png:color-type=6", out]
    result = subprocess.run(cmd, capture_output=True, text=True, cwd="/home/user/igra")
    if result.returncode == 0:
        print(f"Regenerated card_{district}_512.png")
    else:
        print(f"Failed card_{district}: {result.stderr[:150]}")

def regenerate_locked(district):
    inp = os.path.join(cards_dir, f"card_{district}_512.png")
    locked = os.path.join(cards_dir, f"card_{district}_locked_512.png")
    temp1 = inp + ".temp1"
    cmd1 = ["convert", inp, "-evaluate", "pow", "0.55", "-colorspace", "gray", temp1]
    result1 = subprocess.run(cmd1, capture_output=True, text=True, cwd="/home/user/igra")
    if result1.returncode == 0 and os.path.exists(temp1):
        cmd2 = ["convert", temp1, "#0c1016", "-blur", "0x7", "-fill", "#0c1016", "-colorize", "100", locked]
        result2 = subprocess.run(cmd2, capture_output=True, text=True, cwd="/home/user/igra")
        try: os.remove(temp1)
        except: pass
        if result2.returncode == 0:
            print(f"Created locked card_{district}_512.png")
        else:
            print(f"Failed locked2_{district}: {result2.stderr[:100]}")
    else:
        print(f"Failed locked1_{district}: {result1.stderr[:150]}")

if __name__ == "__main__":
    print("Regenerating unlocked cards (cinematic key-art style):")
    for d in target_cards:
        regenerate_unlocked(d)
    print("\nCreating locked variants (night-darkened + desat + fog):")
    for d in target_cards:
        regenerate_locked(d)
    print("\nDone! Regenerated cards:")
    for d in target_cards:
        print(f"  - card_{d}_512.png")
        print(f"  - card_{d}_locked_512.png")
