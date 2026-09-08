# Player-visible changes

Running log, newest batch first. Written for the owner doing manual
in-game verification — a static-only pass can't play the game itself.

---

## Batch 1 (2026-09-08) — severe/major static-audit fixes

- **Escape no longer sometimes force-quits to the main menu.** A dead
  leftover screen was eating every Escape press alongside the real pause
  menu.
- **7 previously-dead skill-tree purchases now do something**:
  Max Health, Stamina Boost, Battery Capacity, Health Regen, Light
  Radius, Damage Boost I/II, Crit Chance, Fire Rate, Reload Speed, Loot
  Luck. Before this batch, buying any of these cost real skill points
  for zero effect.
- **Skill bonuses survive Continue now.** Previously, reloading a save
  silently reset every stat-boosting skill (Max Health, Stamina Boost,
  Battery Capacity, Move Speed, Inventory Space, Light Radius) back to
  base, even though the skill still showed as "unlocked" in the menu.
- **World lighting no longer flickers/changes when a district you're not
  in gets restored.** It used to react to any district's power stage,
  not just the one you're standing in.
- **A renamed/removed inventory item can no longer occupy a permanent
  blank slot.**
- **"Collect all documents" is a real completionist goal again** instead
  of trivially done from the first two districts' lore notes.

### HUMAN 5-MINUTE CHECK
1. New Game → open the Skill Tree (default key, see Controls) → buy one
   level of **Max Health** in Survival and **Damage Boost I** in Combat.
   Confirm the skill shows "Level 1/x" and is no longer purchasable-then-
   silent (max HP number in the HUD top-left should visibly increase by
   ~20 after the Max Health buy).
2. Fire a weapon a few times after buying Damage Boost I/Fire Rate —
   shots should feel very slightly faster to fire (fire_rate) and hit
   harder (watch an enemy's HP bar drop faster than before the buy).
3. Save (pause menu → Save), then Continue from the main menu. Reopen
   the Skill Tree: the bought skills should still show as unlocked, AND
   your max HP/stamina/battery numbers should still reflect the bonus
   (not reset to the unboosted default).
4. During normal gameplay, press Escape a dozen times in a row (menu
   open/close, walking around). You should only ever see the Pause
   menu — never get bounced to the main menu unexpectedly.
5. Pick up a few battery/scrap items in the starting district; confirm
   the pickup count still looks sane (Loot Luck at level 0 should look
   identical to before this pass).
