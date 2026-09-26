#!/usr/bin/env bash
# Полная проверка проекта одной командой.
#
#   ./tools/check.sh                  # все проверки
#   ./tools/check.sh --static         # только те, что не требуют Godot
#   GODOT=/path/to/godot ./tools/check.sh
#
# Код возврата 0 — всё зелёное, иначе число проваленных проверок.

set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
# На Windows `python3`/`py` часто это заглушка Microsoft Store — берём первый реально работающий.
PY="${PY:-}"
[[ -z "$PY" ]] && for c in python3 python py; do "$c" -c '' 2>/dev/null && { PY="$c"; break; }; done
[[ -z "$PY" ]] && { echo "Python не найден"; exit 1; }
STATIC_ONLY=0
[[ "${1:-}" == "--static" ]] && STATIC_ONLY=1

PASS=0
FAIL=0
GREEN=$'\033[32m'; RED=$'\033[31m'; DIM=$'\033[2m'; OFF=$'\033[0m'

ok()   { PASS=$((PASS+1)); echo "  ${GREEN}OK${OFF}   $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ${RED}FAIL${OFF} $1"; }
head_() { echo; echo "── $1"; }

# ─────────────────────────── статические проверки ───────────────────────────
head_ "Статические проверки (Godot не нужен)"

"$PY" - <<'PY'
import json,glob,os,re,sys
fails=[]

# 1. Битые ссылки на ресурсы в сценах и ресурсах
bad=[]
for p in glob.glob('scenes/**/*.tscn',recursive=True)+glob.glob('**/*.tres',recursive=True):
    if '/.git' in p: continue
    try: t=open(p,encoding='utf-8',errors='ignore').read()
    except Exception: continue
    for m in re.findall(r'path="res://([^"]+)"',t):
        if not os.path.exists(m): bad.append((p,m))
print(('  OK   ' if not bad else '  FAIL ')+f'ссылки на ресурсы ({len(bad)} битых)')
if bad:
    fails.append('resources')
    for p,m in bad[:10]: print('         ',p,'->',m)

# 2. Автозагрузки существуют
cfg=open('project.godot',encoding='utf-8').read()
auto=re.findall(r'^(\w+)="\*?(res://[^"]+)"',cfg.split('[autoload]')[1].split('\n[')[0],re.M)
miss=[(n,p) for n,p in auto if not os.path.exists(p[6:])]
print(('  OK   ' if not miss else '  FAIL ')+f'автозагрузки ({len(auto)} шт., {len(miss)} битых)')
if miss: fails.append('autoload')

# 3. Обращения к несуществующим членам автозагрузок
mem={}
for n,p in auto:
    f=p[6:]
    if not os.path.exists(f): continue
    t=open(f,encoding='utf-8').read()
    mem[n]=(set(re.findall(r'^func (\w+)',t,re.M))
      |set(re.findall(r'^(?:@export\s+)?(?:var|const)\s+(\w+)',t,re.M))
      |set(re.findall(r'^signal (\w+)',t,re.M))
      |set(re.findall(r'^enum (\w+)',t,re.M)))
builtin={'has_signal','has_method','call','get','set','connect','emit','is_connected',
 'call_deferred','get_node_or_null','free','queue_free','add_child','get_children',
 'set_deferred','duplicate','get_class','notification','is_inside_tree','get_parent'}
errs=[]
if mem:
    pat=re.compile(r'\b(%s)\.(\w+)'%'|'.join(mem))
    for root,d,fs in os.walk('scripts'):
        for f in fs:
            if not f.endswith('.gd'): continue
            pp=os.path.join(root,f)
            for i,ln in enumerate(open(pp,encoding='utf-8'),1):
                for m in pat.finditer(ln.split('#')[0]):
                    a,x=m.groups()
                    if x not in mem[a] and x not in builtin: errs.append((pp,i,a,x))
print(('  OK   ' if not errs else '  FAIL ')+f'вызовы к автозагрузкам ({len(errs)} несуществующих)')
if errs:
    fails.append('autoload-api')
    for e in errs[:10]: print('         ',*e)

# 4. Локализация: паритет и отсутствующие ключи
locs=sorted(glob.glob('data/i18n/*.json'))
ks=[set(json.load(open(f,encoding='utf-8'))) for f in locs]
parity=all(k==ks[0] for k in ks) if ks else False
ru=json.load(open('data/i18n/ru.json',encoding='utf-8'))
used=set()
for root,d,fs in os.walk('scripts'):
    for f in fs:
        if f.endswith('.gd'):
            t=open(os.path.join(root,f),encoding='utf-8').read()
            used|=set(re.findall(r'LocalizationManager\.tf?\("([^"]+)"',t))
            used|=set(re.findall(r'(?<![\w.])tr\("([^"]+)"\)',t))
missing=sorted(k for k in used if k not in ru)
print(('  OK   ' if parity else '  FAIL ')+f'локализация: {len(locs)} языков x {len(ks[0]) if ks else 0} ключей, паритет={parity}')
print(('  OK   ' if not missing else '  FAIL ')+f'ключи из кода найдены в словаре ({len(missing)} потеряно)')
if not parity: fails.append('i18n-parity')
if missing:
    fails.append('i18n-missing')
    for k in missing[:10]: print('         ',k)

# 5. %-плейсхолдеры совпадают между ru и en
# Без пробела во флагах: раньше "% " (пробел) засчитывался как валидный
# printf-флаг, поэтому обычный текст вида "+15% fire rate"/"25% slower"
# ложно считался форматной подстановкой (нашёлся при добавлении
# SKILL_FIRE_RATE_DESC/SKILL_LIGHT_RADIUS_DESC/SKILL_STEALTH_DESC —
# ни одна реальная подстановка в проекте пробел-флаг не использует).
en=json.load(open('data/i18n/en.json',encoding='utf-8'))
spec=re.compile(r'%[-+#0]*[\d.]*[sdfx]')
mism=[k for k in ru if len(spec.findall(str(ru[k])))!=len(spec.findall(str(en.get(k,''))))]
print(('  OK   ' if not mism else '  FAIL ')+f'плейсхолдеры ru/en ({len(mism)} расхождений)')
if mism: fails.append('i18n-format')

# 6. validate_list указывает на существующие файлы
vl=[l.strip() for l in open('scripts/tools/validate_list.txt') if l.strip()]
vmiss=[l for l in vl if not os.path.exists(l)]
print(('  OK   ' if not vmiss else '  FAIL ')+f'validate_list ({len(vl)} записей, {len(vmiss)} отсутствуют)')
if vmiss: fails.append('validate-list')

# 7. Критический путь: загрузка -> меню -> игра -> районы -> враги
def has(path,needle):
    return os.path.exists(path) and needle in open(path,encoding='utf-8').read()
chain=[
 ('главная сцена = boot_loading', 'boot_loading' in cfg),
 ('boot -> меню', has('scripts/boot_loading.gd','Routes.to_menu')),
 ('меню -> старт игры', has('scripts/ui/main_menu.gd','Routes')),
 ('игровая сцена существует', os.path.exists('scenes/main_3d.tscn')),
 ('main_3d создаёт мир', has('scripts/main_3d.gd','WorldRuntime') or has('scripts/main_3d.gd','_setup_world_runtime')),
 ('мир строит районы', has('scripts/world/world_runtime.gd','DistrictSceneFactory.build')),
 ('районы спавнят врагов', has('scripts/world/district_scene_factory.gd','_spawn_district_enemies')),
 ('районы раскладывают лут', has('scripts/world/district_scene_factory.gd','DistrictLoot.populate')),
]
broken=[n for n,c in chain if not c]
print(('  OK   ' if not broken else '  FAIL ')+f'критический путь игры ({len(chain)-len(broken)}/{len(chain)})')
for n,c in chain:
    if not c: print('          порвано:',n)
if broken: fails.append('critical-path')

# 8. Ресурсы, на которые ссылается код: музыка и звуки монстров
snd=[]
mm=open('scripts/systems/music_manager.gd',encoding='utf-8').read()
for m in re.findall(r'"res://([^"]+\.(?:wav|ogg|mp3))"',mm):
    if not os.path.exists(m): snd.append(m)
print(('  OK   ' if not snd else '  FAIL ')+f'музыкальные треки на диске ({len(snd)} нет)')
if snd: fails.append('music')

sys.exit(len(fails))
PY
RC=$?
if [[ $RC -eq 0 ]]; then PASS=$((PASS+8)); else FAIL=$((FAIL+RC)); fi

# Сцены: комментарии в .tscn, ресурсы в роли [node], битые $NodePath.
head_ "Сцены и ссылки на ноды"
if "$PY" tools/scene_node_check.py; then ok "scene_node_check"; else bad "scene_node_check"; fi

# Ключевой игровой цикл: меню -> уровень -> подбор -> пауза -> меню.
head_ "Игровой цикл"
if "$PY" tools/flow_check.py; then ok "flow_check"; else bad "flow_check"; fi

# Контентные валидаторы из пассов content-depth и retention. Оба приехали
# вместе с контентом и до этого висели отдельными скриптами: секреты, канон
# мира, 60 ежедневок, 6 модификаторов NG+ и 28 подписей больше не проверялись
# ничем после мержа. Держим их в общем прогоне, чтобы правка JSON ломала гейт,
# а не игру.
head_ "Контент: глубина и удержание"
if "$PY" docs/artifacts/content-depth/audit_content_depth.py >/dev/null 2>&1; then
  ok "audit_content_depth"
else
  bad "audit_content_depth"
fi
if "$PY" docs/artifacts/retention/validate_retention.py >/dev/null 2>&1; then
  ok "validate_retention"
else
  bad "validate_retention"
fi

# Order-pass v8 P0 truth gates: visual/audio are real-rendering findings a
# regex/text check can never see (R0: magenta corruption was invisible to
# every check above, only a real windowed GPU frame showed it). visual_truth_gate
# runs against the committed R0 evidence frames as a permanent regression lock
# (docs/RUN_STATE.md has the before/after numbers); it needs no live Godot,
# just the PNGs already in the repo. audio needs a real audio device, so it
# lives in the engine-checks section below instead (self-skips headless, same
# pattern as perf_check_scene.tscn's draw-call gate).
head_ "Truth gates: visual/i18n (данные уже в репозитории)"
if "$PY" tools/qa_sim/visual_truth_gate.py docs/stills/evidence/r0_after_*.png >/dev/null 2>&1; then
  ok "visual_truth_gate (gate self-consistency on committed frames; R0 lock = LUT pin below)"
else
  bad "visual_truth_gate (gate self-consistency on committed frames; R0 lock = LUT pin below)"
fi
# The PNG lock above only re-measures OLD committed frames. The real R0
# cause (2026-09-25, windowed A/B): the 11 district LUTs were imported as
# CompressedTexture2D, which Environment.adjustment_color_correction reads
# as a 1D gradient - a 256x16 16-slice 3D LUT sampled that way turns the
# world magenta with banding rings (world hue-magenta 13% -> 0.03%). Earlier
# "clean" frames were clean only because the textures failed to load.
# Pin: every LUT must stay a Texture3D import.
if ! grep -L 'importer="3d_texture"' assets/textures/luts/lut_*.png.import | grep -q .; then
  ok "R0 root cause pinned (11 district LUTs import as Texture3D)"
else
  bad "district LUT no longer a Texture3D import - world renders magenta (see RUN_STATE 2026-09-25)"
fi
if "$PY" tools/qa_sim/i18n_truth_gate.py >/dev/null 2>&1; then
  ok "i18n_truth_gate"
else
  bad "i18n_truth_gate (см. 'python tools/qa_sim/i18n_truth_gate.py' - overflow это статическая эвристика по длине строки, не подтверждённый визуально баг, см. docs/RUN_STATE.md)"
fi
if bash tools/qa_sim/user_data_guard.sh --demo >/dev/null 2>&1; then
  ok "user_data_guard --demo (snapshot/restore профиля)"
else
  bad "user_data_guard --demo (snapshot/restore профиля)"
fi
if "$PY" tools/qa_sim/hardcoded_text_gate.py >/dev/null 2>&1; then
  ok "hardcoded_text_gate (no untranslated words assigned to .text)"
else
  bad "hardcoded_text_gate (см. 'python tools/qa_sim/hardcoded_text_gate.py')"
fi
# Static, source-driven sims (STATIC_AUDIT #6/#31, PLAYABLE IDEAL TASK 3) —
# built, correct, but never wired into any gate until this P2 pass.
if "$PY" tools/qa_sim/puzzle_economy_sim.py >/dev/null 2>&1; then
  ok "puzzle_economy_sim (STATIC_AUDIT #31 reachability)"
else
  bad "puzzle_economy_sim"
fi
if "$PY" tools/qa_sim/endings_sim.py >/dev/null 2>&1; then
  ok "endings_sim (all 5 GDD endings reachable)"
else
  bad "endings_sim"
fi
if "$PY" tools/qa_sim/balance_sim.py >/dev/null 2>&1; then
  ok "balance_sim (economy/battery/skill-branch/time-to-win)"
else
  bad "balance_sim"
fi
if "$PY" tools/qa_sim/lighting_stage_sim.py >/dev/null 2>&1; then
  ok "lighting_stage_sim (DARK/PARTIAL/STREETS/FULL pairwise-distinct)"
else
  bad "lighting_stage_sim"
fi
if "$PY" tools/qa_sim/a11y_check.py >/dev/null 2>&1; then
  ok "a11y_check (every a11y toggle traces UI -> real effect)"
else
  bad "a11y_check"
fi
# overflow_check.py is a reporting tool (unconditional exit 0, no pass/fail
# assertion) - deliberately not wired as a gate here, see docs/RUN_STATE.md.
if "$PY" tools/qa_sim/drawcall_estimate.py >/dev/null 2>&1; then
  ok "drawcall_estimate (structural draw-call/light estimate, D1)"
else
  bad "drawcall_estimate"
fi
if "$PY" tools/qa_sim/release_export_check.py >/dev/null 2>&1; then
  ok "release_export_check (SECURITY_PATCH_SPEC C-08/D-04: no committed encryption key or debug keystore creds)"
else
  bad "release_export_check (см. 'python tools/qa_sim/release_export_check.py')"
fi

# ─────────────────────────── проверки в движке ───────────────────────────
if [[ $STATIC_ONLY -eq 1 ]]; then
  echo; echo "${DIM}Проверки в движке пропущены (--static).${OFF}"
else
  head_ "Проверки в движке (нужен Godot 4.x)"
  if ! command -v "$GODOT" >/dev/null 2>&1; then
    echo "  ${DIM}Godot не найден в PATH. Укажите путь: GODOT=/путь/к/godot ./tools/check.sh${OFF}"
    echo "  ${DIM}Скачать: https://godotengine.org/download${OFF}"
  else
    # Engine gates run the real game on the owner's user:// profile (New
    # Game, autosave, forged upgrade cfgs): snapshot it, restore on any exit.
    source tools/qa_sim/user_data_guard.sh
    udg_snapshot || { echo "  ${RED}FAIL${OFF} user-data guard: снимок профиля не удался - движковые проверки не запускаются"; exit 1; }
    trap 'udg_restore || exit 97' EXIT
    trap 'exit 130' INT TERM
    export TLS_UDG_GUARDED=1  # tells QaLaunchGuard (qa_launch_guard.gd) this shell guard covers the run
    # RELEASE CONVERGENCE STEP 4: game_test_3d_scene.tscn's phase1+ combat
    # step stalls intermittently under --headless (pre-existing,
    # docs/KNOWN_ISSUES.md "game_test_3d_scene.tscn gate stalls silently") -
    # this used to hang run_gate (and this whole script) forever with no
    # timeout at all, the exact way tools/qa_sim/headless_suite's own
    # run_scene already guards every gate. Same fix here: a per-gate
    # timeout, default matches headless_suite's 90s.
    run_gate() { # имя, сцена, [таймаут-с]
      local name="$1" scene="$2" t="${3:-90}"
      if [[ ! -f "${scene#res://}" ]]; then
        echo "  ${DIM}пропуск${OFF} $name (нет $scene)"; return
      fi
      local out
      out=$(timeout "$t" "$GODOT" --headless --path . "$scene" 2>&1)
      local rc=$?
      if [[ $rc -eq 0 ]]; then ok "$name"
      elif [[ $rc -eq 3 ]]; then echo "  ${DIM}пропуск${OFF} $name (нужен --windowed, не OK/FAIL)"
      elif [[ $rc -eq 124 ]]; then bad "$name (таймаут ${t}s)"; echo "$out" | tail -15 | sed 's/^/         /'
      else bad "$name (код $rc)"; echo "$out" | tail -15 | sed 's/^/         /'; fi
    }
    # ENV RULE (RUN_STATE 2026-09-24): a --headless run cannot regenerate
    # BPTC-compressed textures, and a stale .godot/imported/ cache for the
    # enemy portraits breaks the Encyclopedia autoload -> cascading bogus
    # gate failures (save_slot Nil, "slot B" attack_sim FAIL). One windowed
    # editor pass reimports with real GPU compression. NEVER `git checkout`
    # the .import files afterwards: that re-points them at cache files that
    # do not exist and silently unloads textures. Skip with
    # TLS_SKIP_REIMPORT=1 (e.g. a display-less CI box with a warm cache).
    if [[ "${TLS_SKIP_REIMPORT:-0}" != "1" ]]; then
      if timeout 240 "$GODOT" --editor --quit --path . >/dev/null 2>&1; then ok "реимпорт ассетов (оконный, GPU-сжатие)"; else bad "реимпорт ассетов (оконный) не завершился"; fi
      git checkout -- default_bus_layout.tres 2>/dev/null || true
    fi
    run_gate "компиляция всех скриптов" "res://scenes/tools/compile_gate_scene.tscn"
    run_gate "арность сигналов"          "res://scenes/tools/signal_arity_check_scene.tscn"
    run_gate "API автозагрузок"          "res://scenes/tools/autoload_api_check_scene.tscn"
    run_gate "локализация"               "res://scenes/tools/i18n_check_scene.tscn"
    run_gate "ассеты"                    "res://scenes/tools/asset_check_scene.tscn"
    # P8 (2026-09-21): the scene's OWN HARD_TIMEOUT_SEC (_game_test_3d.gd) is
    # 150s, longer than this gate's old 90s shell timeout - meaning the shell
    # always killed the process before the scene's own graceful timeout
    # handler (which reports the exact stalled phase) ever got to run.
    # Bumped past 150s so the real diagnostic can fire, if it's still stuck.
    run_gate "прогон 3D-сцены"           "res://scenes/tools/game_test_3d_scene.tscn" 170
    run_gate "целостность сейва"         "res://scenes/tools/save_integrity_check_scene.tscn"
    run_gate "крафт-флоу + концовки"     "res://scenes/tools/craft_check_scene.tscn"
    run_gate "adversarial: achievement/NG+/economy/district-id forgery" "res://scenes/tools/attack_sim_scene.tscn"
    run_gate "boot-flow (меню/новая игра/сейв)" "res://scenes/tools/boot_check_scene.tscn" 200
    run_gate "footstep-маппер (surface x speed)" "res://scenes/tools/footstep_check_scene.tscn"
    run_gate "QaLaunchGuard: snapshot/restore профиля (синтетический каталог)" "res://scenes/tools/qa_guard_check_scene.tscn"
    # QaLaunchGuard lifecycle on the real profile (this shell guard still covers it):
    # an unguarded QA run restores at exit; a killed one leaves a verified copy that a
    # guarded launch keeps and the next unguarded launch restores.
    qa_guard_e2e() {
      local U snap probe before
      U=$(udg_dir); snap="$U.qa_snapshot"; probe="$U/qa_guard_probe.save"
      _e2e() { env -u TLS_UDG_GUARDED timeout 60 "$GODOT" --headless --path . res://scenes/tools/qa_guard_e2e_scene.tscn -- "$1" >/dev/null 2>&1; }
      _hash() { (cd "$U" && { find . -maxdepth 1 -type f; find ./saves -type f 2>/dev/null; } | sort | xargs -d '\n' sha256sum); }
      before=$(_hash)
      _e2e --write; [[ ! -e "$probe" && ! -d "$snap" ]] || { echo "         --write: probe or copy left behind"; return 1; }
      _e2e --die;   [[ -e "$probe" && -f "$snap/manifest.json" ]] || { echo "         --die: no crash copy"; return 1; }
      timeout 60 "$GODOT" --headless --path . res://scenes/tools/qa_guard_e2e_scene.tscn -- --noop >/dev/null 2>&1
      [[ -f "$snap/manifest.json" ]] || { echo "         guarded launch consumed the crash copy"; return 1; }
      _e2e --noop;  [[ ! -e "$probe" && ! -d "$snap" ]] || { echo "         recovery did not restore the crash copy"; return 1; }
      [[ "$(_hash)" == "$before" ]] || { echo "         profile differs after recovery"; return 1; }
      # A copy that fails its manifest must stop an unguarded QA run before its first frame.
      mkdir -p "$snap/files"; printf x > "$snap/files/lang.cfg"; printf '{"pid": 1, "files": {"lang.cfg": "0"}}' > "$snap/manifest.json"
      _e2e --write && { echo "         damaged copy did not abort the run"; rm -rf -- "$snap"; return 1; }
      [[ ! -e "$probe" && -d "$snap" ]] || { echo "         abort was not airtight"; rm -rf -- "$snap"; return 1; }
      rm -rf -- "$snap"  # the fake copy made just above
    }
    if qa_guard_e2e; then ok "QaLaunchGuard: жизненный цикл (выход, крах, восстановление) на реальном профиле"; else bad "QaLaunchGuard: жизненный цикл на реальном профиле"; fi
    run_gate "аудио: тишина до первого ввода" "res://scenes/tools/audio_hum_check_scene.tscn"
    run_gate "единая тема: chrome виден на всех экранах" "res://scenes/tools/theme_unify_probe_scene.tscn"
    run_gate "настройки: тир графики и accessibility переживают рестарт" "res://scenes/tools/settings_persist_probe_scene.tscn"
    run_gate "accessibility: reduce_flash/time_fx/ui_motion гейтят juice-сайты" "res://scenes/tools/a11y_probe_scene.tscn"
    run_gate "вёрстка: все экраны UIManager в кадре" "res://scenes/tools/ui_layout_check_scene.tscn"
    # GOLD MASTER suite (P0 autoloads, P1 new-game, P1b every input action
    # exercised, P2 districts+loot, P3 save/load+lang, P4 endings, P5 i18n,
    # P6 soak). Built 2026-09 but never wired in until now (P2 matrix-sweep
    # finding). Short soak here for check.sh speed; QA_SOAK_SEC=120 default
    # for a real soak run standalone.
    QA_SOAK_SEC="${QA_SOAK_SEC:-20}" run_gate "GOLD MASTER suite (autoloads/input/districts/save-load/endings/i18n/soak)" "res://scenes/tools/qa_headless_suite_scene.tscn" 120
    # Draw-call budget: --headless всегда даёт draw_calls=0 (dummy renderer) -
    # гейт сам это обнаруживает и молча пропускает (SKIP, не OK/FAIL). Реальная
    # проверка бюджета D11<350 требует --windowed:
    #   tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn
    run_gate "перф-бюджет (draw calls, только --windowed)" "res://scenes/tools/perf_check_scene.tscn" 120
    # Order-pass v8 P0: то же ограничение, что у перф-бюджета выше -
    # --headless не даёт реального аудио-устройства, гейт сам это видит
    # (DisplayServer.get_name()=="headless") и молча пропускает. Реальная
    # проверка ("Music bus реально не в тишине") требует --windowed:
    #   tools/qa_sim/guarded_windowed res://scenes/tools/audio_truth_gate_scene.tscn
    run_gate "аудио: Music bus не в тишине (только --windowed)" "res://scenes/tools/audio_truth_gate_scene.tscn" 60
    run_gate "тач-инпут (joystick/deadzone/HUD-кнопки)" "res://scenes/tools/touch_probe_scene.tscn"
    if udg_restore; then ok "user-data guard: профиль игрока восстановлен байт-в-байт"; else bad "user-data guard: профиль игрока НЕ восстановлен"; fi
  fi
fi

echo
echo "──────────────────────────────────────"
if [[ $FAIL -eq 0 ]]; then
  echo "${GREEN}Всё зелёное.${OFF} Проверок пройдено: $PASS"
else
  echo "${RED}Провалено: $FAIL${OFF}, пройдено: $PASS"
fi
exit $FAIL
