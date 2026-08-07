# THE LAST STREETLIGHT — ART & AUDIO PROMPT (10/10 Target)

## General Style Direction
- Dark post-apocalyptic urban atmosphere. Muted palette dominated by deep charcoal (#1a1a1a), slate blue (#2c3e50), rust orange (#b4452f), and amber/gold (#c9a24a) as the only warm accent.
- All environments feel abandoned, decaying, industrial. Concrete, rusted steel, broken glass, overgrown moss in cracks.
- Lighting is LOW-KEY: almost no ambient light. Player's flashlight is the primary light source. Everything else is dim or pitch black.
- Color grading: desaturated with slight teal-blue shadows and warm amber highlights (flashlight cone).
- Film grain overlay (subtle, 2-3%) for cinematic feel.
- Vignette: dark edges, ember-colored (#b4452f) pulse when enemies are near.

---

## ENVIRONMENT / TERRAIN

### Tile System (9×9 grid per district, each tile = 64×64px at 16px/unit → 4 tiles wide per district cell)
- **tile_floor.png**: 256×256px, seamless tileable. Dark concrete with hairline cracks. Color: #2a2a2a base, #333333 crack lines, subtle water stains in #1a2a3a. Roughness: high (matte). No specular.
- **tile_wall.png**: 256×256px, seamless. Brutalist concrete blocks, some bricks missing (exposed rebar). Color: #3a3530 base, #2a2520 shadow joints, #4a4540 highlight edges. Height variation: 2px bump map.
- **tile_ceiling.png**: 256×256px, dark industrial ceiling. Exposed pipes (#4a4a4a), conduit (#3a3a3a), dust layers (#5a5040 translucent). Seamless.
- **tile_door.png**: 128×256px (2×1 tile). Heavy steel door, rusted, half-open or closed. Color: #2a2520 body, #8a7060 rust spots, #c9a24a emergency strip (1px horizontal stripe at 3/4 height).
- **tile_window.png**: 128×128px. Shattered window frame (steel #3a3a3a), broken glass shards (#8899aa with alpha gradient), darkness behind.
- **tile_stairs_down.png**: 128×128px. Concrete steps descending, guardrail (#4a4a4a), warning strip (#b4452f).
- **tile_stairs_up.png**: 128×128px. Inverse of down.

### District-Specific Palette (overrides base tile colors)
| District | Base Wall | Floor Accent | Fog Color | Ambient Tint |
|----------|-----------|-------------|-----------|-------------|
| Suburbs | #3a3530 | #4a5a3a (grass cracks) | #0a0a14 | #1a1a2e |
| Residential | #2e2e32 | #3a3a3a (asphalt) | #0c0c18 | #1c1c2e |
| Park | #2a3a2a | #3a4a2a (moss) | #0a140a | #1a2e1a |
| School | #3a3530 | #3a3a40 (linoleum) | #0c0c14 | #1e1e2e |
| Hospital | #3a3838 | #4a4848 (tile) | #0c0c10 | #1e1e22 |
| Gas Station | #3a3a2a | #4a4a3a (oil stains) | #14140a | #2e2e1a |
| Police | #2a2a30 | #3a3a40 (concrete) | #0a0a12 | #1a1a2a |
| Warehouses | #3a3530 | #3a3530 (dirt) | #0e0e10 | #1e1e20 |
| Industrial | #3a302a | #4a403a (slag) | #14100a | #2e2a1a |
| Substation | #2a2a30 | #3a3a40 (metal grating) | #0a0a14 | #1a1a2e |
| Power Station | #2a2a2a | #3a3a3a (char) | #080808 | #1a1a1a |

---

## PLAYER (player_fps.tscn)

### Player Model (placeholder until GLB provided)
- **image.png** (player placeholder): 512×512px, transparent PNG. Silhouette of a figure in dark hoodie + pants, holding a flashlight in right hand. Color: solid #1a1a2e (dark silhouette), flashlight cone glow #c9a24a at hand level.
- **Flashlight cone mesh**: SpotLight3D attached to Camera3D. Cone angle 45° (upgradable to 75°), range 8m (upgradable to 13m), color #c9a24a, energy 2.0, shadow enabled (1024×1024).
- **Flashlight beam shader**: GPUParticles3D, quad mesh, billboard, blend_add, color #c9a24a at 30% opacity, lifetime 2s, spread 15°, gravity 0, speed 0.5 (drift). Max 50 particles.

### Player HUD Elements
- **Battery bar**: 200×16px, horizontal. Background #0c1016, fill #c9a24a (gradient to #f0c040 at full). Border #2a3340, 1px.
- **Weight bar**: 200×8px, same style, fill #b4452f when >70%, #c9a24a when <70%.
- **Stamina bar**: 200×8px, fill #4a9ab5 (teal).
- **Health bar**: 200×12px, fill #b4452f (ember red).

---

## ENEMIES (5 types + Boss)

### Shadow (shadow_3d.tscn)
- **Model**: 512×512px placeholder image.png. Humanoid silhouette, entirely #0a0a14 (near-black), edges glow #1a1a3e (faint blue). Semi-transparent (alpha 0.7).
- **Size**: 1.8m tall, 0.6m wide. CapsuleShape3D hurtbox: radius 0.3, height 1.6.
- **Particle effect**: GPUParticles3D, 20 particles, color #1a1a4e, lifetime 1s, spread 360°, speed 1.0 (dissolve effect on death).
- **Death**: fade-out over 3s (modulate alpha 1→0), particles burst.

### Crawler (crawler_3d.tscn)
- **Model**: 512×512px. Low-slung insectoid, 4 limbs, #2a1a0a (dark brown). Glowing red eyes (#b4452f, 2px dots).
- **Size**: 0.8m tall, 1.2m long. Hurtbox: radius 0.4, height 0.6.
- **Movement**: low crouch, 1.5× speed.
- **Death**: ragdoll (RigidBody3D), 2s then queue_free.

### Watcher (watcher_3d.tscn)
- **Model**: 512×512px. Tall thin figure, #3a3a4a (grey-blue), no facial features except 2 glowing white eyes (#ffffff, 3px). Floating 0.3m above ground.
- **Size**: 2.4m tall, 0.4m wide. Hurtbox: radius 0.3, height 1.8.
- **Vision cone**: visible cone mesh (SpotLight3D, inner angle 45°, outer 60°, range 12m, color #ffffff at 5% opacity).
- **Scream**: AudioStreamPlayer3D, range 15m, OGG, pitch 0.7, volume -6dB.

### Hunter (hunter_3d.tscn)
- **Model**: 512×512px. Athletic humanoid in dark tactical gear, #1a2a3a (dark blue-grey). Glowing red eyes (#b4452f). Shoulder-mounted light (#c9a24a, small SpotLight3D, range 5m).
- **Size**: 1.9m tall, 0.7m wide. Hurtbox: radius 0.35, height 1.7.
- **Charge attack**: lean forward, speed ×1.3 for 1.5s, knockback 3m.

### Destroyer (destroyer_3d.tscn)
- **Model**: 512×512px. Massive humanoid, #4a3a2a (rust-brown), mechanical parts visible (exposed gears #6a6a6a, cables #3a3a3a). 2.2m tall.
- **Size**: 2.2m tall, 1.0m wide. Hurtbox: radius 0.5, height 2.0. Armor: 30% damage reduction.
- **Death**: explosion particles (GPUParticles3D, 100 particles, #b4452f + #c9a24a, lifetime 2s), screen shake (intensity 0.5, duration 0.5).

### Boss — The Architect (boss_architect_3d.tscn)
- **Model**: 1024×1024px (hero asset). Giant Watcher-like figure, #1a1a2e body, #c9a24a circuit-like veins glowing across torso and arms. 3.5m tall.
- **Phase 1**: Standard Watcher form, teleportation (instant reposition, particle trail #c9a24a).
- **Phase 2**: Becomes invisible in dark (modulate alpha 0.0), only visible when in flashlight cone (reveals #c9a24a veins). Spawns 3 Shadow minions (shadow_3d.tscn).
- **Phase 3**: Arena destruction. Falling debris (StaticBody3D + GPUParticles3D), 40 dmg per hit.
- **Hurtbox**: radius 1.0, height 3.0.
- **Boss health bar**: 400×20px, centered top of screen. Background #0c1016, fill gradient #b4452f → #c9a24a.

---

## ITEMS / PICKUPS

### Item Icons (128×128px, PNG with alpha)
| Item | Icon Description | Background |
|------|-----------------|------------|
| Battery | Cylindrical battery shape, #4a9ab5 body, #c9a24a lightning bolt | #0c1016 |
| Medkit | Red cross (#b4452f) on white (#ffffff) box | #1a2a1a |
| Key | Golden key (#c9a24a), simple shape | #2a2a1a |
| Cable | Coiled copper cable (#b87333) | #1a1a1a |
| Fuse | Glass tube (#88aacc) with #b4452f filament | #2a2a2a |
| Transformer | Metal box (#4a4a4a) with #c9a24a coils | #1a1a2a |
| Blueprint | Parchment (#c4a86a) with #2a2a2a lines | #1a1a0a |
| Coin | Gold circle (#c9a24a) with #8a6a2a edge | #0c1016 |
| Document | White (#ffffff) paper with #2a2a2a text lines | #1a1a1a |
| Photo | Border #c9a24a, image #3a3a3a | #0c1016 |
| Weapon (pistol/rifle/shotgun) | Silhouette in #2a2a2a, #c9a24a accents | #1a1a1a |

---

## UI / HUD ELEMENTS

### ThemeProvider Colors (used in code)
- `COLOR_AMBER`: #c9a24a — primary accent (buttons, highlights, flashlight)
- `COLOR_EMBER`: #b4452f — danger/warning (health, visibility pulse, enemy indicators)
- `COLOR_TEAL`: #4a9ab5 — info/stamina
- `COLOR_PANEL`: #141b24 — panel backgrounds
- `COLOR_PANEL_EDGE`: #2a3340 — panel borders
- `COLOR_TEXT`: #d8d2c4 — primary text
- `COLOR_TEXT_DIM`: #6a6a7a — dim text
- `COLOR_BG`: #0c1016 — main background

### HUD Layout (CanvasLayer, layer 10)
- **Top-left**: Mini-map (128×128px, circular mask, #0c1016 bg, district icons #c9a24a)
- **Top-center**: District name label (font_size 18, color #c9a24a)
- **Top-right**: Battery bar (200×16px), weight bar (200×8px)
- **Bottom-left**: Movement controls indicator (joystick visual, 80px touch target)
- **Bottom-center**: Action buttons (Attack #c9a24a, Dodge #4a9ab5, Interact #b4452f)
- **Bottom-right**: Minimap + stealth indicator (ember pulse when detected)
- **Center**: Interaction prompt (when near interactable, 300×40px, #141b24 bg, #c9a24a text)
- **Top-center (objective)**: Current quest objective text, 300×30px, #d8d2c4

### Menu Screens (all 26 screens per SCREEN_LIST)
- **Main Menu**: 1920×1080, bg #0c1016, title "THE LAST STREETLIGHT" in #c9a24a (font_size 48), 5 buttons stacked vertically (each 300×50px, #141b24 bg, #2a3340 border, #c9a24a text on hover)
- **Settings**: 800×600 panel, sliders for volume (0-100, #c9a24a fill), toggle for fullscreen, sensitivity 0.5-2.0×, deadzone 5-25%
- **Inventory**: 600×400, grid of 4×3 slots (64×64px each, #141b24 bg, #2a3340 border, item icon centered)
- **Journal**: 700×500, quest list with checkboxes, objectives indented
- **Bestiary**: 800×600, grid of monster portraits (128×128px each, locked/unlocked)
- **Character**: Stats panel, bars for HP/stamina/battery/weight
- **Flashlight Upgrade**: 5 upgrade levels, each 200×80px card, locked/unlocked/equipped states
- **Photo Mode**: Overlay with #c9a24a corner brackets, filter icons row at bottom
- **Victory Screen**: 1920×1080, fade-in from black, stats (time, districts, documents, secrets), 3 buttons (Main Menu, New Game+, Quit)
- **Death Screen**: 1920×1080, red vignette (#b4452f at 40% opacity), reason text, 3 buttons (Last Checkpoint, Load, Main Menu)

---

## AUDIO SPECIFICATIONS

### Bus Layout (Project Settings → Audio Buses)
```
Master
├── Music (volume -12dB, soloable)
├── SFX (volume 0dB)
│   ├── Footsteps
│   ├── Combat
│   ├── UI
│   └── Environment
└── Voice (volume -6dB)
```

### Music Layers (adaptive, crossfade 2s)
| Layer | File | Duration | Description |
|-------|------|----------|-------------|
| Ambient_Dark | ambient_dark.ogg | 120s loop | Low drone, cold, minimal. Pitch 0.8. OGG 128kbps. |
| Ambient_Lit | ambient_lit.ogg | 90s loop | Warmer, hopeful tones added. OGG 128kbps. |
| Threat_Low | threat_low.ogg | 60s loop | Subtle tension pad, starts when enemy in INVESTIGATE |
| Threat_High | threat_high.ogg | 45s loop | Pulsing bass, heartbeat 60bpm, CHASE state |
| Action | action_sting.ogg | 8s one-shot | Melee hit, dodge whoosh, damage taken |
| Environment_Rain | rain.ogg | 180s loop | Rain ambience, masks footsteps |
| UI_Hover | ui_hover.ogg | 0.5s one-shot | Brass click, warm |
| UI_Click | ui_click.ogg | 0.3s one-shot | Wood/knuckle tap |
| UI_Error | ui_error.ogg | 0.4s one-shot | Low buzz |

### Footstep System (S9.2)
- 6 surface types, 3 speeds each = 18 audio files:
  - `footstep_asphalt_quiet.ogg`, `footstep_asphalt_loud.ogg`, `footstep_asphalt_silent.ogg`
  - `footstep_concrete_quiet.ogg`, etc.
  - `footstep_wood_quiet.ogg`, etc.
  - `footstep_metal_quiet.ogg`, etc.
  - `footstep_puddle_quiet.ogg` (splash, +reverb)
  - `footstep_glass_quiet.ogg` (crunch)
- Format: OGG, 44100Hz, mono, <20KB each
- Playback: RayCast3D down from player feet → determine surface → play at volume 0.3-0.8 based on speed

### Monster Audio
| Monster | Sound File | Range | Description |
|---------|-----------|-------|-------------|
| Shadow | shadow_teleport.ogg | 15m | Electric zap, 0.3s, pitch 0.5 |
| Crawler | crawler_scratch.ogg | 10m | Metal scraping, loop 2s, volume -8dB |
| Watcher | watcher_breath.ogg | 5m | Heavy breathing, loop 4s, volume -6dB |
| Watcher | watcher_scream.ogg | 15m | High-pitched shriek, 1.5s, volume -3dB |
| Hunter | hunter_steps.ogg | 8m | Heavy boots, loop 1.5s |
| Hunter | hunter_roar.ogg | 12m | Pre-charge warning, 1s |
| Destroyer | destroyer_hum.ogg | 12m | Mechanical drone, loop 6s |
| Boss | architect_laugh.ogg | 25m | Deep laugh, 2s |

### UI Audio
- All UI sounds: WAV, <50KB each, OGG compressed for final
- Button hover: 0.1s, brass ping, pitch +2 semitones
- Button press: 0.05s, wood tap
- Achievement unlock: 1.5s, ascending chime, #c9a24a
- Error: 0.3s, low buzz
- Save: 0.2s, soft click

---

## SHADERS

### Flashlight Cone Shader (flashlight_cone.gdshader)
```glsl
shader_type spatial;
render_mode blend_add, unshaded;

uniform vec3 cone_color : source_color = vec3(0.79, 0.64, 0.29); // #c9a24a
uniform float cone_angle : hint_range(10.0, 80.0) = 45.0;
uniform float cone_length : hint_range(1.0, 20.0) = 8.0;
uniform float softness : hint_range(0.0, 1.0) = 0.3;
uniform float intensity : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    // cone shape with edge falloff
    ALBEDO = cone_color * intensity;
    ALPHA = 0.08; // subtle additive
}
```

### Dust Particles Shader (dust_particles.gdshader)
```glsl
shader_type spatial;
render_mode blend_add, unshaded;

uniform vec4 dust_color : source_color = vec4(0.79, 0.64, 0.29, 0.3);
uniform float lifetime : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    ALBEDO = dust_color.rgb;
    ALPHA = dust_color.a * (1.0 - TIME / lifetime);
}
```

### Vignette Shader (vignette.gdshader) — post-process
```gdscript
shader_type canvas_item;
uniform vec4 vignette_color : source_color = vec4(0.706, 0.271, 0.184, 1.0); // #b4452f
uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_SIZE;
    float dist = length(uv - 0.5) * 2.0;
    float vignette = smoothstep(0.3, 1.0, dist);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    COLOR = vec4(vignette_color.rgb, vignette * intensity * pulse);
}
```

---

## PARTICLE SYSTEMS

| System | Count | Mesh | Blend | Color | Lifetime | Use |
|--------|-------|------|-------|-------|----------|-----|
| Flashlight dust | 50 | Quad | Additive | #c9a24a 30% | 2s | Player flashlight |
| Shadow dissolve | 20 | Quad | Additive | #1a1a4e | 1s | Shadow death |
| Destroyer explosion | 100 | Quad | Additive | #b4452f + #c9a24a | 2s | Destroyer death |
| Rain | 500 | Quad | Additive | #8899aa 20% | 3s | Weather (rain districts) |
| Firefly | 30 | Quad | Additive | #aaffaa 40% | 4s | Park district ambient |
| Spark (fuse box) | 15 | Point | Additive | #ffaa44 | 0.5s | Puzzle interactions |

---

## PERFORMANCE TARGETS (S13)
- Draw calls: <200 District 1, <350 District 11
- Poly count: <50K per district
- Dynamic lights: <8 per district (rest baked)
- Shadows: moon 2048×2048, flashlight 1024×1024
- Texture max: 2048×2048 hero, 512×512 props
- Format: Basis Universal (ETC2/ASTC)
- Particles: <500 simultaneous
- RAM: <800MB peak
- VRAM: <400MB
- Audio: OGG, <50MB SFX, <100MB music
