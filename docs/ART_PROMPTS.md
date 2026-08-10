# ART PROMPTS — Meshy.ai

Промпты для генерации 3D-моделей через Meshy.ai. Движок: Godot 4.7, GL Compatibility,
mobile-target (полигоны <50K на район, текстура модели ≤2048²). Экспорт: `.glb` → `assets/models/<категория>/`.
Код НЕ блокируется на арте: до подмены стоят плейсхолдеры (`scripts/tools/_replace_placeholders.gd`).

Общий суффикс ко всем промптам (добавлять при сабмите):
```
, dark horror style, matte non-metallic surfaces, muted colors,
single material with 1024x1024 albedo, no interior, no rig
```

## 1. ВРАГИ (GDD §6.2)

### 1.1. shadow (Shadow — тёмно-синий силуэт, слуховик)
```
gaunt humanoid silhouette 2.2m tall, featureless matte pitch-black skin,
elongated arms to knees, thin tapered fingers, no face, slightly hunched,
low-poly horror monster
```
Сила: силуэт читается в темноте; emissive-глаз нет (он слепой).

### 1.2. crawler (Crawler — бурый скарпион-ползун, слебой собака)
```
quadruped crawling horror creature 1m long, mottled brown chitinous skin,
flat elongated segmented body low to ground, multiple small limbs under body,
blind head with sensory whiskers, low-poly
```
Арахнофоб-режим (GDD §14): тот же prompt с blind hairless dog вместо limbs → crawler_safe.glb

### 1.3. watcher (Watcher — наблюдающий сталкер)
```
gaunt tall humanoid 2m, pale grey cracked flesh, wide unblinking single central eye,
hanging spindly arms, motionless statue-like pose, dim glow from eye, low-poly horror
```

### 1.4. hunter (Hunter — зрительный охотник, cone 60°)
```
athletic gaunt predator humanoid 1.9m, dessicated dark grey leathery skin,
sunken many-faceted eyes, jaw split into two mandibles, predatory forward-lean stance,
low-poly horror
```

### 1.5. destroyer (Destroyer — тяжёлый разрушитель, не реагирует на свет)
```
massive hulking humanoid brute 2.4m, swollen rock-hard grey-black flesh,
cracked plates of skin like cooled slag, one oversized right fist, head sunk
in shoulders, no visible eyes, low-poly horror
```

### 1.6. architect (Босс — The Architect, 3 фазы)
```
tall skeletal humanoid 3m, multiple fused asymmetrical limbs, head is composite
angular mineral structure with many glowing sockets, floating posture with trailing
dark ethereal cloak, phase-state blurring at edges, low-poly boss monster
```

## 2. ОРУЖИЕ (GDD §18)

FPS-слой: `weapon_pistol.gd`, `weapon_rifle.gd`, `weapon_shotgun.gd` (класс `WeaponBase`).

### 2.1. pistol
```
worn semi-automatic pistol, scratched dark steel frame, used industrial,
simple iron sights, tape wrapped grip, low-poly game-ready
```

### 2.2. rifle
```
weathered bolt-action rifle, scratched dark metal, worn wooden stock with scratches,
simple iron sights, low-poly game-ready
```

### 2.3. shotgun
```
double-barrel shotgun, scratched dark metal barrels, worn wooden stock with hand scratches,
hinged break-action, simple brass sight, low-poly game-ready
```
Ограничение: без оптики, без ювелирки — стиль "выживание".

## 3. РЕКВИЗИТ (окружение, assets/models/environment/)

Пакет под ключевые точки. По GDD §15: полигоны в кадре минимальны, использовать LOD.
Реально используем Kenney-плейсхолдеры, генерируем кастом под ключевые моменты.

| id | prompt |
|----|--------|
| generator | `old rusty uninterruptible power generator, peeling olive paint, exposed wires` |
| bench | `wooden carpenter workbench, scratched surface, vice on edge, low-poly` |
| manhole | `rusty cast-iron manhole cover, grimy, slightly cracked` |
| kiosk_beer | `small derelict street kiosk with broken front, rusted metal frame, cracked boards` |
| autodom | `abandoned elderly vending machine, faded beverage branding, cracked glass, rusted` |
| transformer | `old heavy transformer box, oil stains, loose cables, caution plate worn` |
| newspaper_stand | `rundown metal newsstand stand, empty shelves, peeling paint` |
| hydrant | `old fire hydrant, chipped red paint, rusty bolts` |
| bench_park | `broken wooden park bench with metal armrests, one slat missing` |
| barricade | `makeshift barricade from planks and a bent road sign` |

## 4. ЭКСПОРТ
- Формат: GLB (≠ gltf), без rig для props/врагов (у них внешний FSM).
- Анимации монстров/игрока: Mixamo (см. `docs/ANIMATION_GUIDE.md`).
- Текстура: albedo 1024², без эмиссии (эффекты на сцене).
