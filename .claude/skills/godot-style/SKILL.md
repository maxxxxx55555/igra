---
name: godot-style
description: GDScript style and safety rules. Apply whenever writing or editing .gd files.
---
Rules: static typing everywhere; @export for tunables; snake_case; avoid polling in _process - use signals/timers; check is_instance_valid for freed nodes; scripts over 300 lines must be split; comment only non-obvious "why".