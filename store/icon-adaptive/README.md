# Android adaptive icon — export layers

Two layers, both 1080x1080, derived deterministically from the menu art
`assets/ui/menu_city.png` (Gemini, `docs/ASSET_LICENSES.md`) by
`tools/gen_adaptive_icon.py`, which also writes the three 512 icons
(`store/icon-512.png`, `assets/store/play_icon_512.png`,
`assets/ui/icon.png`) from the same picture:

| File | Role | Notes |
|---|---|---|
| `foreground_1080x1080.png` | adaptive icon foreground | RGBA, fully transparent: the picture is the background. |
| `background_1080x1080.png` | adaptive icon background | RGBA, fully opaque. The lamp, its light cone and the puddle of the menu art; the inner 66.7% that every mask shows holds the lamp head. Per-channel values clamped to `[16,216]` (~`#101418`..`#d8d2c4`) so there is no pure `#000`/`#fff` texel. |

## Wiring (Godot 4.7 Android export preset)

In `export_presets.cfg` under `[preset.0.options]` (the Android preset) —
already wired:

```
launcher_icons/adaptive_foreground_432x432="res://store/icon-adaptive/foreground_1080x1080.png"
launcher_icons/adaptive_background_432x432="res://store/icon-adaptive/background_1080x1080.png"
```

Godot downscales these to the 432 slot on export; supplying 1080 keeps
the source crisp. `launcher_icons/main_192x192` (the legacy square
launcher icon) stays on `res://assets/store/play_icon_512.png`. Android
crops the background to the device mask shape (circle / squircle /
rounded square).

Play Console's own 512x512 store icon is a separate upload — use
`store/icon-512.png` there, unchanged.
