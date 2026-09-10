# Android adaptive icon — export layers

Two layers, both 1080x1080, derived deterministically from
`store/icon-512.png` by `tools/gen_adaptive_icon.py` (re-run it if the
512 master changes):

| File | Role | Notes |
|---|---|---|
| `foreground_1080x1080.png` | adaptive icon foreground | RGBA. The 512 crest scaled into the inner 66% safe zone, centred, on a fully transparent field. Per-channel values clamped to `[16,216]` (~`#101418`..`#d8d2c4`) so there is no pure `#000`/`#fff` texel. |
| `background_1080x1080.png` | adaptive icon background | RGBA, fully opaque. Flat STYLE_GUIDE "panel" `#141b24`. |

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
composites fg over bg and crops to the device mask shape (circle /
squircle / rounded square); the 66% safe zone keeps the crest fully
visible under every mask.

Play Console's own 512x512 store icon is a separate upload — use
`store/icon-512.png` there, unchanged.
