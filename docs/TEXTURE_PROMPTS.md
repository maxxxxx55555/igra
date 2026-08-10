# TEXTURE PROMPTS — seamless HD

Бесшовные (tileable) материалы для наложения на 3D-геометрию и UI-фоны дистриктов.
Движок: Godot 4.7, GL Compatibility; цель — mobile (GDD §15).
Экспорт: PNG 1024×1024 → `assets/textures/environment/` (albedo). Normal/rough —
генерить из albedo в Materialize/NormalMap Online, класть рядом.

Общий суффикс ко всем промптам:
```
, photorealistic seamless texture, tileable, flat lighting, no seams,
no watermarks, no text, dark muted post-soviet urban horror style
```

## 1. ASPHALT (асфальт — ul. Fonarского района)
Файл: `asphalt_albedo.png`
```
worn cracked asphalt road surface, multiple repair patches, faint oil stains,
small potholes, diffuse gray color with dusty particles
```
Вариант B (влажный): добавить `wet, damp sheen, slight reflection` → `asphalt_wet_albedo.png`.

## 2. CONCRETE (бетон — стены, фундаменты, подвалы D2/D9)
Файл: `concrete_albedo.png`
```
old concrete wall surface, subtle cracks, dust and grime stains,
slight efflorescence, flat gray color
```
Вариант B (тыква следа): добавить `vertical mold streaks` → `concrete_basement_albedo.png`.

## 3. BRICK (кирпич — фасады D1/D4)
Файл: `brick_albedo.png`
```
aged red clay brick wall, weathered mortar joints, some spalling and chips,
faded paint traces
```
Вариант B (тёмный): `dark burnt brick` → `brick_dark_albedo.png`.

## 4. RUSTY METAL (ржавый металл — трубы, ограждения, реквизит)
Файл: `rusty_metal_albedo.png`
```
rusted corrugated metal sheet, deep brown rust texture with little remaining
gray paint, drip streaks, pitted surface
```

## 5. DIRT (грунт — парки, дворы, зоны Flee)
Файл: `dirt_albedo.png`
```
dry compact dirt ground with small stones, twigs, and irregular patches,
dark brown earth tone
```

## 6. Каналы в Godot
- Albedo: `res://assets/textures/environment/<name>_albedo.png`.
- Normal/Roughness/AO: опционально `<name>_normal.png`, `<name>_rough.png` —
  подключается в StandardMaterial3D; если нет — ORM не используется.
- UV-повторение: подбирается в материале сцены; текстуры строго tileable.
