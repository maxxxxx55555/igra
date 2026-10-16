# Phase A Design Spec — UI flow, FTUE, atmosphere, HUD

Approved scope:

- A1: state-driven UI visibility using existing `GameManager` state and `EventBus.game_state_changed`.
- A2: wire existing PowerGrid/DistrictManager/EventBus/puzzle/toast systems for the suburbs first-run flow.
- A3: adjust existing environment, lighting, and theme resources/scripts only; no new manager/autoload.
- A4: add ten battery segments using existing `EventBus.player_battery_changed` and add sprint FOV lerp to the existing external camera script.

Constraints:

- Absolute paths under `C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT` only.
- Preserve autoloads and existing 2D systems.
- No shell commands in this session.
- Gates are NOT RUN; the user runs them.
- One commit per phase and one final PR.
