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

python3 - <<'PY'
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
en=json.load(open('data/i18n/en.json',encoding='utf-8'))
spec=re.compile(r'%[-+ #0]*[\d.]*[sdfx]')
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
 ('районы раскладывают лут', has('scripts/world/district_scene_factory.gd','LOOT_SCRIPT.populate')),
]
broken=[n for n,c in chain if not c]
print(('  OK   ' if not broken else '  FAIL ')+f'критический путь игры ({len(chain)-len(broken)}/{len(chain)})')
for n,c in chain:
    if not c: print('          порвано:',n)
if broken: fails.append('critical-path')

# 8. Ресурсы, на которые ссылается код: музыка и звуки монстров
snd=[]
mm=open('scripts/systems/music_manager.gd',encoding='utf-8').read()
for m in re.findall(r'"res://([^"]+\.(?:wav|ogg))"',mm):
    if not os.path.exists(m): snd.append(m)
print(('  OK   ' if not snd else '  FAIL ')+f'музыкальные треки на диске ({len(snd)} нет)')
if snd: fails.append('music')

sys.exit(len(fails))
PY
RC=$?
if [[ $RC -eq 0 ]]; then PASS=$((PASS+8)); else FAIL=$((FAIL+RC)); fi

# Сцены: комментарии в .tscn, ресурсы в роли [node], битые $NodePath.
head_ "Сцены и ссылки на ноды"
if python3 tools/scene_node_check.py; then ok "scene_node_check"; else bad "scene_node_check"; fi

# Ключевой игровой цикл: меню -> уровень -> подбор -> пауза -> меню.
head_ "Игровой цикл"
if python3 tools/flow_check.py; then ok "flow_check"; else bad "flow_check"; fi

# ─────────────────────────── проверки в движке ───────────────────────────
if [[ $STATIC_ONLY -eq 1 ]]; then
  echo; echo "${DIM}Проверки в движке пропущены (--static).${OFF}"
else
  head_ "Проверки в движке (нужен Godot 4.x)"
  if ! command -v "$GODOT" >/dev/null 2>&1; then
    echo "  ${DIM}Godot не найден в PATH. Укажите путь: GODOT=/путь/к/godot ./tools/check.sh${OFF}"
    echo "  ${DIM}Скачать: https://godotengine.org/download${OFF}"
  else
    run_gate() { # имя, сцена
      local name="$1" scene="$2"
      if [[ ! -f "${scene#res://}" ]]; then
        echo "  ${DIM}пропуск${OFF} $name (нет $scene)"; return
      fi
      local out
      out=$("$GODOT" --headless --path . "$scene" 2>&1)
      local rc=$?
      if [[ $rc -eq 0 ]]; then ok "$name"
      else bad "$name (код $rc)"; echo "$out" | tail -15 | sed 's/^/         /'; fi
    }
    run_gate "компиляция всех скриптов" "res://scenes/tools/compile_gate_scene.tscn"
    run_gate "арность сигналов"          "res://scenes/tools/signal_arity_check_scene.tscn"
    run_gate "API автозагрузок"          "res://scenes/tools/autoload_api_check_scene.tscn"
    run_gate "локализация"               "res://scenes/tools/i18n_check_scene.tscn"
    run_gate "ассеты"                    "res://scenes/tools/asset_check_scene.tscn"
    run_gate "прогон 3D-сцены"           "res://scenes/tools/game_test_3d_scene.tscn"
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
