# Economy funding-path options — repeat-profile coin shortfall

Analysis only, per `docs/DESIGN_AUDIT_ARENA.md` P6's ledger (still the source of truth for the
numbers below — not re-derived, just cited): a repeat-profile player with no secrets banks
**2,200** coins (11 districts × 200, `scripts/economy/rewards_manager.gd`), against **3,500**
to buy the two priciest catalog items (brightness 1,500 + slots 2,000, `data/shop/*.tres`) —
a **1,300-coin gap**, with the audit's own "0 repeatable-grind income" framing.

**One correction to that framing, found while scoping this doc, not a new option**: the
daily-challenge system (`scripts/systems/daily_challenge_manager.gd`) already pays real
`CoinWallet.add()` coins on completion (`content/daily_challenges.json`, 60 templates,
reward range 10-780, average **216.5**) plus streak bonuses — it's real, wallet-crediting,
repeatable income, just gated by real calendar days, not reachable within one sitting (which
is why the audit's single-playthrough trace correctly excluded it). Closing a 1,300-coin gap
through dailies alone takes roughly 6 real-world days at the average reward. This doesn't
close the gap, but "0 repeatable income" is not quite accurate — a returning player already
has a slow path. Worth knowing before picking an option below, since Option A duplicates
income the game already has a version of.

Every row below is a **NEEDS-OWNER-DECISION** item — none of these are implemented in this
pass; this file is the menu, not a change.

## Option A — Wire the existing kill-coin number into `CoinWallet`

`base_monster.gd:687` already computes `randi_range(5, 15)` coins per kill (NG+-scaled) and
emits it on `EventBus.coins_changed` — but every listener on that signal is a HUD label
(`scripts/ui/coin_hud.gd`, `scripts/ui/screens.gd:934`), not `CoinWallet.add()`. The number
displays and evaporates; it was never real currency. Making it real is a one-line change:
call `CoinWallet.add(...)` alongside (or instead of) the existing emit at the kill site.

| | |
|---|---|
| **Current code impact** | Smallest of the three: one call added at `base_monster.gd:687`, no new systems, no data files touched. `EventBus.coins_changed` keeps firing for the HUD either way (cosmetic vs. real can stay in sync trivially). |
| **Player-experience risk** | Highest of the three. This is the option the design-audit explicitly warned against ("Do not add grinding to compensate" — P6, row 3): residential/every district would become stealth-optional if enough forced/opportunistic kills fund the shop, which cuts against a stealth-narrative game's core pillar. A player who avoids combat (the intended playstyle) gets nothing from this; a player who doesn't, gets unlimited income. Needs a cap (e.g., first-kill-per-monster-per-run, or a soft daily ceiling like the existing challenge system) to avoid being a pure grind faucet — that cap is itself a design call, not in the one-line estimate above. |
| **Implementation effort** | Trivial uncapped; small-medium if a cap is added (needs new persistent state to track what's already been paid out, similar to `achievements_manager.gd`'s idempotent-payout pattern already in the codebase). |
| **Reversibility** | High. Removing the `CoinWallet.add()` call reverts to the current (cosmetic-only) behavior with zero data migration, since nothing about `CoinWallet`'s balance format changes. |

## Option B — Reduce the two target catalog prices (data-only)

Cut `data/shop/*.tres` sticker prices for `blueprint_flashlight_brightness` (1,500) and the
slots item (2,000) enough to close the gap at the current 2,200-coin repeat-profile ceiling —
e.g., 1,300 / 1,900 instead (or any split totaling ≤2,200), or extend the existing 30% bundle
discount (`bundle_starter.tres`) to the specific two-item pair the audit's ledger targets.

| | |
|---|---|
| **Current code impact** | Zero code — pure `.tres` resource value edits. No new systems, no new consumers, `shop_item.gd`'s existing discount logic is reused as-is if the bundle-discount route is chosen instead of flat price cuts. |
| **Player-experience risk** | Lowest of the three for correctness (nothing can break), but changes the game's intended economy pacing/tuning — if the current prices were a deliberate "this is meant to take two playthroughs" design choice (unconfirmed either way in the audit or `docs/GDD.md`), cutting them removes that friction permanently for every player, not just the repeat-profile one the gap analysis is about. |
| **Implementation effort** | Trivial — a numeric field change per file, covered by the existing `balance_sim.py` static ledger check (P6's proposal already extends that simulator to verify these two-item purchase examples). |
| **Reversibility** | Very high. Single-field revert per `.tres`, no save-data implications (prices aren't stored per-save). |

## Option C — Add a bounded, reachable-in-one-run coin faucet via the existing quest/puzzle path

`scripts/core/quest_manager.gd:123` and `scripts/world/puzzle_system.gd:73` already make real
`CoinWallet` calls (per the audit, these exist but weren't traced for reachability/amount this
pass). Add one new, capped, single-completion side objective per district (or a subset) that
pays into the gap — e.g., a repeatable-per-district but once-per-save puzzle reward, similar
in spirit to how `achievements_manager.gd` idempotently pays out district-specific bonuses.

| | |
|---|---|
| **Current code impact** | Medium — reuses the existing quest/puzzle wallet-call pattern (no new payment plumbing needed), but needs new quest/puzzle content authored per district (or however many districts the owner picks to carry it) plus i18n strings for any new objective text across all 13 locales. |
| **Player-experience risk** | Lowest of the three for pillar-fit — an authored, capped objective (vs. open-ended kill grinding) keeps the stealth-narrative pacing intact and gives every playstyle (not just combat-heavy) a path to the gap, closer to how the district secrets already work. Risk is scope creep: "one puzzle per district" is itself 11 small content pieces, not a single edit. |
| **Implementation effort** | Highest of the three — needs content authoring (puzzle/quest design per district) plus i18n, not just a number or a signal wire-up. Could be scoped down to 1-2 districts covering the 1,300 gap instead of all 11, which would cut this to medium effort. |
| **Reversibility** | Medium. Removing a shipped quest after players have already completed it and banked the coins doesn't claw back currency (same one-way-door property `docs/IDEAL_GAP_REPORT.md` already notes for achievement payouts) — reversible in code/content, not in already-affected save files. |

## Not proposed as an option, and why

- **Do nothing / treat the gap as intentional friction** is a legitimate fourth answer the
  owner may pick — the audit itself frames it as one of three outcomes ("new faucet, reduced
  prices, or accept the gap as intentional friction"). Not tabled as a row above since it's a
  decision to make, not an implementation path to evaluate; noted here so it isn't missed.
