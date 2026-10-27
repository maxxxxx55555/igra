# THE LAST STREETLIGHT — инструкции внутри единого PowerShell-файла

Передай другой ИИ только `Igra-MegaRelease(2).ps1`. Дополнительные файлы из чата
не требуются. Файл содержит проверяемый SHA256 git bundle с исправлениями и
эту инструкцию. База — точный публичный PR #31, коммит
`bf563cc9353dd1fb3717943b416530e6a9e4fb2c`. Его исходники скрипт получает из
GitHub; итоговый коммит указан в SourceHead. Старый отдельный промпт не нужен.

## Запуск

На Windows 10/11, обычный PowerShell, из папки с файлом:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Igra-MegaRelease(2).ps1" -Repository maxxxxx55555/igra
```

По умолчанию скрипт загружает исходники в НОВУЮ уникальную ветку
release/1.0.1-..., проверяет SHA256 bundle, точный коммит и SHA ветки после push.
Существующую ветку защищает пустое expected lease, main не изменяется.
Если нужен вход, используется обычный GitHub CLI с браузером. Пароли и токены
в чат не отправлять. Скрипт напечатает ссылку, рабочую папку и путь к CONTINUE.md.
SOURCE_SAVED означает только сохранение исходников.

Прочитать инструкцию без установки, входа и загрузки:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Igra-MegaRelease(2).ps1" -Instructions
```

-SourceOnly — совместимый с прежним файлом синоним обычного запуска.
-Build включает проверки, сборки Windows/Web и черновик GitHub Release.
-Android включает тот же конвейер плюс подписанный AAB. Автоматической
публикации в Play Console нет. Полная сборка заблокируется до исправления AF3.
После новых коммитов не запускай старый встроенный payload для их сборки:
работай в напечатанной рабочей копии и заново создавай файл командой
`python tools/release/package.py <новый.ps1>`.

## Исправления в пакете

1. Удалены вызовы неизвестных достижений district_one, shadow_slayer,
   secret_hunter. Статический аудит обнаруживает неизвестные внешние ID.
   Каталог сохраняет 31 достижение. Менеджер уже отклонял неизвестные ID,
   поэтому действительная награда не удалена. _districts_restored сохранён:
   он нужен get_stats; его удаление сломало бы статистику.
2. Проверка всех объявленных звуковых петель обязательна в статической
   батарее, предел скачка 0.037. Пропавшее объявление или ffmpeg — ошибка.
   ffmpeg добавлен в установку Windows и CI. Звуки не перегенерированы.
3. Подписанный Android должен пройти проверку текущего сертификата,
   целостности, отсутствия секретов и постороннего содержимого. Manifest
   читается официальным bundletool: package, versionCode и versionName
   сверяются с Android export preset, debuggable отклоняется. JDK tools
   используют стабильный язык вывода; успешный текст при ненулевом exit
   больше не принимается. bundletool 1.18.3 скачивается с google/bundletool,
   SHA256 a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29.
4. Переведены 15 интерфейсных подписей в de/fr/pt_BR; словарь и integrity
   manifest обновлены. Поддерживаются ru/en/es/de/fr/pt_BR, 1566 ключей.
5. Список кадров читается без /dev/fd. Proof logs пишет один tee-процесс:
   сохраняются вложенный вывод и настоящий exit footer. При ошибке записи
   лога команда не выдаёт успех.
6. Холодный импорт Godot с exit 0 и ошибками предварительного preload
   получает одну строгую повторную проверку. Исходные ошибки остаются в
   отчёте; RECOVERED_IMPORT ставится только после чистого повторного импорта.
   Повторяющиеся ошибки, timeout и ненулевой exit останавливают сборку.
   Все compile/resource gates выполняются после импорта.

## Уже было в PR — не переделывать по устаревшим предположениям

Четыре запрошенных one-shot уже существуют; GEMINI_HANDOFF содержит все 19
целевых файлов. Листинг обещает 58 доступных ежедневных испытаний, правильно:
из 60 написанных selector исключает streets_12/16. Баланс не менять.
В emissive_windows.gd нет _collect_walls; используется MultiMesh и
../StreetBuilder. Не добавлять выдуманную правку устаревшего промпта.
Совпадение перевода с английским может быть именем, единицей или общим словом;
это не доказательство отсутствия перевода.

## AF3 — обязательные новые кадры

После изменений runtime/data восемь кадров docs/stills/store устарели.
Нужна реальная съёмка, просмотр и коммит. Не ослаблять AF3, не переименовывать
старые изображения как новые, не подделывать время и измерения.
В рабочей копии, Git Bash на машине с графическим Godot 4.7.2:

```bash
export GODOT='C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
export TLS_FRAMES_OUT='res://.qa_logs/final_frames/'
bash tools/qa_sim/proof_run --launch final_frames -- bash tools/qa_sim/guarded_windowed res://scenes/tools/final_frames_scene.tscn 600
python tools/qa_sim/stamp_frames.py .qa_logs/final_frames .qa_logs/final_stamped "$(git rev-parse --short=12 HEAD)" --only 01_main_menu,02_district_day_full,03_district_night_dark,04_combat,05_boss,06_victory_ngplus,07_skill_tree,08_shop
python tools/qa_sim/af3_frame_check.py --dir .qa_logs/final_stamped
```

Сначала безопасно импортируй ресурсы в отдельной копии. Сохраняй исходный
байтовый default_bus_layout.tres и чужие правки. Runner уменьшает кадры вдвое:
проверь реальные размеры и качество. Просмотри все восемь. Старые кадры
архивируй с исходными байтами/именами/датами, обнови ссылки, новые установи
вместо них в docs/stills/store. Добавление рядом со старыми не закроет AF3.

## Полные проверки финального коммита

Прочитай CLAUDE.md, AGENT_ZONES.md, PRODUCTION_BIBLE.md. Старые узкие
OpenCode/Cline-зоны поглощены main. Не удаляй непроверенные игровые ресурсы.
Не изменяй баланс и навигацию без причины и трёхсидового теста.
Проверки запускать с защитой user:// и полными логами:

```bash
bash tools/qa_sim/proof_run --launch final_all_1 -- bash tools/check.sh --all
bash tools/qa_sim/proof_run --launch final_all_2 -- bash tools/check.sh --all
bash tools/qa_sim/proof_run --launch final_headless -- bash tools/qa_sim/headless_suite
QA_SEEDS="1 2 3" bash tools/qa_sim/proof_run --launch final_bot -- bash tools/qa_sim/autoplay_bot
bash tools/qa_sim/proof_run --launch final_perf -- bash tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn
python tools/flow_check.py
python tools/scene_node_check.py
python tools/lint_changed.py
python tools/release/test_release.py
```

Нужны маркеры завершения, отсутствие script/resource errors и три WIN с
проверенными счётчиками. Exit 0 сам по себе недостаточен. Python pipeline
не заменяет два буквальных запуска check.sh --all. Не засчитывай пропуски
PowerShell-тестов как успешное выполнение. Результаты прежних временных
копий не являются доказательствами нового SourceHead. Свежие результаты
пакета записаны в docs/SINGLE_SCRIPT_VERIFICATION.md; оставшиеся engine,
GPU, сохранения, звук, физическое устройство и сборку проверять отдельно.

## Android, права и публикация

Используй существующий приватный upload key. Не генерируй новую личность
подписи и не коммить пароли. SHA256 текущего сертификата:
`a4a7c2c27e7892f158faa78f51076a937d318ec0f82558a2c021b2cbb5dfcc9f`.
Ожидается package com.maxsimkasky.laststreetlight, code 7, name 1.0.1.
Если code 7 уже занят в Console, сначала выбери свободный больший code,
затем пересобери. JDK 17; SDK platform 36, build-tools 36.1.0,
NDK 29.0.14206865; лицензии принимает владелец через sdkmanager.

```bash
python tools/qa_sim/aab_check.py <новый.aab> --secrets --bundletool <bundletool-all-1.18.3.jar>
python tools/qa_sim/release_export_check.py --aab <новый.aab>
```

Запиши фактический SHA256 AAB, размер, source commit, manifest, подпись и
полные логи в RELEASE_ARTIFACTS. Старые code 5/6 не являются новой сборкой.
Документация инструмента: https://developer.android.com/tools/bundletool ;
https://github.com/google/bundletool/releases/tag/1.18.3 .

Владелец предоставляет реальный privacy contact и проверяет URL политики,
подтверждает коммерческие права на музыку либо разрешает замену, выполняет
физический Android-playtest и заполняет Play Console. Не выдумывай эти результаты.
Не останавливай чужие Java-процессы; допустим только Gradle этого проекта.

Проверь актуальные main, PR #31 и CI через gh. Ветка уже содержит #31,
не переносить его коммиты повторно. Интегрируй через проверенный PR,
повторно проверь merged tree и строй именно его. Публикацию, branch protection,
Pages и Console этот пакет не выполнял. Не удалять gh-pages и другие ветки
без доказательств сохранности их работы. Релиз завершён только после реальной
проверки и одобренной владельцем публикации.
