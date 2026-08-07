# THE LAST STREETLIGHT — ФИНАЛ (код + визуал референса + звук)
Сборка БЕЗ Python: part1.ps1..part6.ps1 в одну папку tls_build (UTF-8), затем в cmd папки:
  copy /b part1.ps1+part2.ps1+part3.ps1+part4.ps1+part5.ps1+part6.ps1 build_all.ps1
  powershell -ExecutionPolicy Bypass -File build_all.ps1
Открой THE_LAST_STREETLIGHT/project.godot в Godot 4.7 Stable -> F5. Рендерер GL Compatibility.
Визуал в стиле референса работает СРАЗУ (программно). Опционально сохрани PNG-арт
(tile_floor/tile_wall/player_top/coin_icon/menu_bg.png) в assets/art/ — подхватится сам.
Мир НЕ процедурный и НЕ бесконечный (канон): одна фиксированная карта из 11 районов.