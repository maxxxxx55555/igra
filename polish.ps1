# ============================================================================
# polish.ps1 -- THE_LAST_STREETLIGHT  (FINAL BUILD - ALL 4 PARTS)
# Complete build: audio gen, i18n, night env, HUD, gameplay, LAN, Android export
# ============================================================================
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
}

function Add-Autoload([string]$name, [string]$path) {
	$godotFile = Join-Path $root 'project.godot'
	if (-not (Test-Path $godotFile)) { Write-Host ('WARN project.godot missing -- skipping ' + $name); return }
	$text = [System.IO.File]::ReadAllText($godotFile, $utf8)
	if ($text -match ('^' + [regex]::Escape($name) + '=')) {
		Write-Host ('AUTOLOAD ' + $name + ' (exists)'); return
	}
	$entry = ($name + '="*' + $path + '"') + [Environment]::NewLine
	if ($text -match '\[autoload\]\s*\r?\n') {
		$newText = [regex]::Replace($text, '(\[autoload\]\s*\r?\n)', ('$1' + $entry), 1)
		[System.IO.File]::WriteAllText($godotFile, $newText, $utf8)
	} else {
		$append = [Environment]::NewLine + '[autoload]' + [Environment]::NewLine + $entry
		[System.IO.File]::AppendAllText($godotFile, $append, $utf8)
	}
	Write-Host ('AUTOLOAD ' + $name + ' -> ' + $path)
}

function Ensure-Dir([string]$rel) {
	$full = Join-Path $root $rel
	if (-not (Test-Path $full)) {
		[void](New-Item -ItemType Directory -Force -Path $full)
		Write-Host ('MKDIR    ' + $rel)
	}
}

function Run-Python([string]$scriptRel) {
	$candidates = @('python', 'py', 'python3')
	foreach ($py in $candidates) {
		$cmd = Get-Command $py -ErrorAction SilentlyContinue
		if ($cmd) {
			Write-Host ('RUN     ' + $py + ' ' + $scriptRel)
			& $py (Join-Path $root $scriptRel) $root
			return $LASTEXITCODE
		}
	}
	Write-Host 'WARN no python found -- skipping'
	return 0
}

function Write-Po([string]$loc, [hashtable]$trans) {
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.AppendLine("# Locale: $loc  -- THE_LAST_STREETLIGHT")
	[void]$sb.AppendLine('msgid ""')
	[void]$sb.AppendLine('msgstr ""')
	[void]$sb.AppendLine('"Content-Type: text/plain; charset=UTF-8\n"')
	[void]$sb.AppendLine(('"Language: ' + $loc + '\n"'))
	[void]$sb.AppendLine('')
	foreach ($k in ($trans.Keys | Sort-Object)) {
		[void]$sb.AppendLine('msgid "' + $k + '"')
		[void]$sb.AppendLine('msgstr "' + $trans[$k] + '"')
		[void]$sb.AppendLine('')
	}
	Write-Utf8 ('locale/' + $loc + '.po') $sb.ToString()
}

# ============================================================================
# PART 1: Bootstrap + Audio Gen + I18n
# ============================================================================
Write-Host ''
Write-Host '===== PART 1: Bootstrap + Audio Gen + I18n =====' -ForegroundColor Cyan

Ensure-Dir 'audio/music'
Ensure-Dir 'audio/ambient'
Ensure-Dir 'audio/sfx'
Ensure-Dir 'locale'
Ensure-Dir 'tools'
Ensure-Dir 'scripts/i18n'
Ensure-Dir 'scripts/visual'

$bootstrap = @'
extends Node
## Autoload "Bootstrap".  Idempotent folder check + boot banner.  No order deps.

func _ready() -> void:
	_ensure_folders()
	print("[Bootstrap] THE_LAST_STREETLIGHT ready  os=", OS.get_name(), " locale=", OS.get_locale(), " dpr=", OS.get_screen_max_scale())

func _ensure_folders() -> void:
	var d := DirAccess.open("res://")
	if d == null:
		push_warning("[Bootstrap] cannot open res:// for folder check")
		return
	for sub in ["audio/music", "audio/ambient", "audio/sfx", "screenshots", "saves"]:
		if not d.dir_exists(sub):
			d.make_dir_recursive(sub)

static func boot_info() -> Dictionary:
	return {"ts": Time.get_datetime_string_from_system(), "v": "1.0-final"}
'@
Write-Utf8 'scripts/_bootstrap.gd' $bootstrap
Add-Autoload 'Bootstrap' 'res://scripts/_bootstrap.gd'

# Part 1 version of gen_audio (will be overwritten by Part 2 with CANON districts)
$gen_audio_v1 = @'
#!/usr/bin/env python3
"""gen_audio.py -- initial version (placeholder districts)."""
import sys
print("[gen_audio] placeholder -- will be overwritten with CANON districts")
sys.exit(0)
'@
Write-Utf8 'tools/gen_audio.py' $gen_audio_v1

$i18n = @'
extends Node
## Autoload "I18n".  Loads 13 .po locale files, sets locale from OS or saved pref.

const LOCALES: PackedStringArray = [
	"en", "ru", "es", "fr", "de", "it", "pt", "ja", "ko", "zh", "ar", "tr", "pl"
]
const DEFAULT_LOCALE: StringName = &"en"

var _current: StringName = &""
var _ready_done: bool = false

func _ready() -> void:
	_load_all()
	call_deferred("_apply_locale")

func _load_all() -> void:
	for loc in LOCALES:
		var path := "res://locale/%s.po" % loc
		if not FileAccess.file_exists(path):
			continue
		var tr_res := Translation.new()
		tr_res.locale = _to_godot_locale(loc)
		var err := tr_res.load_from_file(ProjectSettings.globalize_path(path))
		if err == OK:
			TranslationServer.add_translation(tr_res)
			print("[I18n] loaded locale ", loc)
		else:
			push_warning("[I18n] failed to load locale %s (err %d)" % [loc, err])

func _to_godot_locale(code: String) -> String:
	match code:
		"zh": return "zh_CN"
		"pt": return "pt_BR"
		"en": return "en_US"
		_: return code

func _detect() -> StringName:
	var os_locale := OS.get_locale()
	var lang := os_locale.substr(0, 2).to_lower()
	if LOCALES.has(lang):
		return StringName(lang)
	return DEFAULT_LOCALE

func _apply_locale() -> void:
	set_locale(_detect())
	_ready_done = true

func set_locale(loc: StringName) -> void:
	TranslationServer.set_locale(_to_godot_locale(String(loc)))
	_current = loc

func current() -> StringName:
	return _current

func t(key: StringName) -> String:
	return tr(String(key))

func is_ready() -> bool:
	return _ready_done

func list_locales() -> PackedStringArray:
	return LOCALES
'@
Write-Utf8 'scripts/i18n/i18n.gd' $i18n
Add-Autoload 'I18n' 'res://scripts/i18n/i18n.gd'

$keys_en = @{
	'hud_power'='Power'; 'hud_coins'='Coins'; 'hud_district'='District'; 'hud_lives'='Lives';
	'menu_play'='Play'; 'menu_host'='Host LAN'; 'menu_join'='Join LAN'; 'menu_quit'='Quit';
	'shop_battery'='Battery +25%'; 'shop_medkit'='Medkit'; 'shop_stamina'='Stamina';
	'shop_not_enough'='Not enough coins';
	'msg_saved'='Game saved'; 'msg_caught'='You were caught!';
	'msg_win'='All districts powered!'; 'msg_lose'='You failed...';
	'interact_switch'='Power switch'; 'interact_shop'='Shop';
	'confirm'='Confirm'; 'cancel'='Cancel'
}
Write-Po 'en' $keys_en

$keys_ru = @{
	'hud_power'='Энергия'; 'hud_coins'='Монеты'; 'hud_district'='Район'; 'hud_lives'='Жизни';
	'menu_play'='Играть'; 'menu_host'='Создать LAN'; 'menu_join'='Войти LAN'; 'menu_quit'='Выход';
	'shop_battery'='Батарея +25%'; 'shop_medkit'='Аптечка'; 'shop_stamina'='Выносливость';
	'shop_not_enough'='Не хватает монет';
	'msg_saved'='Игра сохранена'; 'msg_caught'='Вас поймали!';
	'msg_win'='Все районы запитаны!'; 'msg_lose'='Вы проиграли...';
	'interact_switch'='Рубильник'; 'interact_shop'='Магазин';
	'confirm'='Подтвердить'; 'cancel'='Отмена'
}
Write-Po 'ru' $keys_ru

$keys_es = @{
	'hud_power'='Energía'; 'hud_coins'='Monedas'; 'hud_district'='Distrito'; 'hud_lives'='Vidas';
	'menu_play'='Jugar'; 'menu_host'='Crear LAN'; 'menu_join'='Unirse LAN'; 'menu_quit'='Salir';
	'shop_battery'='Batería +25%'; 'shop_medkit'='Botiquín'; 'shop_stamina'='Aguante';
	'shop_not_enough'='Monedas insuficientes';
	'msg_saved'='Partida guardada'; 'msg_caught'='¡Te atraparon!';
	'msg_win'='¡Todos los distritos con luz!'; 'msg_lose'='Has fallado...';
	'interact_switch'='Interruptor'; 'interact_shop'='Tienda';
	'confirm'='Confirmar'; 'cancel'='Cancelar'
}
Write-Po 'es' $keys_es

$keys_fr = @{
	'hud_power'='Énergie'; 'hud_coins'='Pièces'; 'hud_district'='Quartier'; 'hud_lives'='Vies';
	'menu_play'='Jouer'; 'menu_host'='Créer LAN'; 'menu_join'='Rejoindre LAN'; 'menu_quit'='Quitter';
	'shop_battery'='Batterie +25%'; 'shop_medkit'='Trousse'; 'shop_stamina'='Endurance';
	'shop_not_enough'='Pas assez de pièces';
	'msg_saved'='Partie sauvée'; 'msg_caught'='Vous avez été pris !';
	'msg_win'='Tous les quartiers alimentés !'; 'msg_lose'='Échec...';
	'interact_switch'='Interrupteur'; 'interact_shop'='Boutique';
	'confirm'='Confirmer'; 'cancel'='Annuler'
}
Write-Po 'fr' $keys_fr

$keys_de = @{
	'hud_power'='Energie'; 'hud_coins'='Münzen'; 'hud_district'='Viertel'; 'hud_lives'='Leben';
	'menu_play'='Spielen'; 'menu_host'='LAN erstellen'; 'menu_join'='LAN beitreten'; 'menu_quit'='Beenden';
	'shop_battery'='Batterie +25%'; 'shop_medkit'='Verband'; 'shop_stamina'='Ausdauer';
	'shop_not_enough'='Nicht genug Münzen';
	'msg_saved'='Spiel gespeichert'; 'msg_caught'='Du wurdest gefangen!';
	'msg_win'='Alle Viertel versorgt!'; 'msg_lose'='Gescheitert...';
	'interact_switch'='Schalter'; 'interact_shop'='Laden';
	'confirm'='Bestätigen'; 'cancel'='Abbrechen'
}
Write-Po 'de' $keys_de

$keys_it = @{
	'hud_power'='Energia'; 'hud_coins'='Monete'; 'hud_district'='Quartiere'; 'hud_lives'='Vite';
	'menu_play'='Gioca'; 'menu_host'='Crea LAN'; 'menu_join'='Unisciti LAN'; 'menu_quit'='Esci';
	'shop_battery'='Batteria +25%'; 'shop_medkit'='Medkit'; 'shop_stamina'='Resistenza';
	'shop_not_enough'='Monete insufficienti';
	'msg_saved'='Partita salvata'; 'msg_caught'='Sei stato preso!';
	'msg_win'='Tutti i quartieri alimentati!'; 'msg_lose'='Hai fallito...';
	'interact_switch'='Interruttore'; 'interact_shop'='Negozio';
	'confirm'='Conferma'; 'cancel'='Annulla'
}
Write-Po 'it' $keys_it

$keys_pt = @{
	'hud_power'='Energia'; 'hud_coins'='Moedas'; 'hud_district'='Distrito'; 'hud_lives'='Vidas';
	'menu_play'='Jogar'; 'menu_host'='Criar LAN'; 'menu_join'='Entrar LAN'; 'menu_quit'='Sair';
	'shop_battery'='Bateria +25%'; 'shop_medkit'='Kit médico'; 'shop_stamina'='Resistência';
	'shop_not_enough'='Moedas insuficientes';
	'msg_saved'='Jogo salvo'; 'msg_caught'='Você foi pego!';
	'msg_win'='Todos os distritos ligados!'; 'msg_lose'='Você falhou...';
	'interact_switch'='Interruptor'; 'interact_shop'='Loja';
	'confirm'='Confirmar'; 'cancel'='Cancelar'
}
Write-Po 'pt' $keys_pt

$keys_ja = @{
	'hud_power'='電力'; 'hud_coins'='コイン'; 'hud_district'='地区'; 'hud_lives'='ライフ';
	'menu_play'='プレイ'; 'menu_host'='LANホスト'; 'menu_join'='LAN参加'; 'menu_quit'='終了';
	'shop_battery'='バッテリー+25%'; 'shop_medkit'='救急キット'; 'shop_stamina'='スタミナ';
	'shop_not_enough'='コイン不足';
	'msg_saved'='セーブしました'; 'msg_caught'='捕まりました!';
	'msg_win'='全地区点灯!'; 'msg_lose'='失敗...';
	'interact_switch'='スイッチ'; 'interact_shop'='ショップ';
	'confirm'='確認'; 'cancel'='キャンセル'
}
Write-Po 'ja' $keys_ja

$keys_ko = @{
	'hud_power'='전력'; 'hud_coins'='코인'; 'hud_district'='구역'; 'hud_lives'='생명';
	'menu_play'='플레이'; 'menu_host'='LAN 호스트'; 'menu_join'='LAN 참가'; 'menu_quit'='종료';
	'shop_battery'='배터리 +25%'; 'shop_medkit'='구급함'; 'shop_stamina'='스태미나';
	'shop_not_enough'='코인 부족';
	'msg_saved'='저장됨'; 'msg_caught'='잡혔습니다!';
	'msg_win'='모든 구역 점등!'; 'msg_lose'='실패...';
	'interact_switch'='스위치'; 'interact_shop'='상점';
	'confirm'='확인'; 'cancel'='취소'
}
Write-Po 'ko' $keys_ko

$keys_zh = @{
	'hud_power'='电力'; 'hud_coins'='金币'; 'hud_district'='区域'; 'hud_lives'='生命';
	'menu_play'='开始'; 'menu_host'='创建LAN'; 'menu_join'='加入LAN'; 'menu_quit'='退出';
	'shop_battery'='电池+25%'; 'shop_medkit'='医疗包'; 'shop_stamina'='体力';
	'shop_not_enough'='金币不足';
	'msg_saved'='已保存'; 'msg_caught'='被抓住了!';
	'msg_win'='所有区域已点亮!'; 'msg_lose'='失败...';
	'interact_switch'='开关'; 'interact_shop'='商店';
	'confirm'='确认'; 'cancel'='取消'
}
Write-Po 'zh' $keys_zh

$keys_ar = @{
	'hud_power'='طاقة'; 'hud_coins'='عملات'; 'hud_district'='حي'; 'hud_lives'='أرواح';
	'menu_play'='ابدأ'; 'menu_host'='إنشاء LAN'; 'menu_join'='انضمام LAN'; 'menu_quit'='خروج';
	'shop_battery'='بطارية +25%'; 'shop_medkit'='إسعاف'; 'shop_stamina'='تحمل';
	'shop_not_enough'='عملات غير كافية';
	'msg_saved'='تم الحفظ'; 'msg_caught'='تم الإمساك بك!';
	'msg_win'='كل الأحياء مضاءة!'; 'msg_lose'='فشلت...';
	'interact_switch'='المفتاح'; 'interact_shop'='المتجر';
	'confirm'='تأكيد'; 'cancel'='إلغاء'
}
Write-Po 'ar' $keys_ar

$keys_tr = @{
	'hud_power'='Enerji'; 'hud_coins'='Jeton'; 'hud_district'='Bölge'; 'hud_lives'='Canlar';
	'menu_play'='Oyna'; 'menu_host'='LAN kur'; 'menu_join'="LAN'a katıl"; 'menu_quit'='Çıkış';
	'shop_battery'='Pil +25%'; 'shop_medkit'='İlk yardım'; 'shop_stamina'='Dayanıklılık';
	'shop_not_enough'='Yetersiz jeton';
	'msg_saved'='Oyun kaydedildi'; 'msg_caught'='Yakalandın!';
	'msg_win'='Tüm bölgeler aydınlandı!'; 'msg_lose'='Başarısız...';
	'interact_switch'='Şalter'; 'interact_shop'='Mağaza';
	'confirm'='Onayla'; 'cancel'='İptal'
}
Write-Po 'tr' $keys_tr

$keys_pl = @{
	'hud_power'='Energia'; 'hud_coins'='Monety'; 'hud_district'='Dzielnica'; 'hud_lives'='Życia';
	'menu_play'='Graj'; 'menu_host'='Stwórz LAN'; 'menu_join'='Dołącz LAN'; 'menu_quit'='Wyjdź';
	'shop_battery'='Bateria +25%'; 'shop_medkit'='Apteczka'; 'shop_stamina'='Wytrzymałość';
	'shop_not_enough'='Za mało monet';
	'msg_saved'='Zapisano'; 'msg_caught'='Złapano!';
	'msg_win'='Wszystkie dzielnice zasilone!'; 'msg_lose'='Porażka...';
	'interact_switch'='Przełącznik'; 'interact_shop'='Sklep';
	'confirm'='Potwierdź'; 'cancel'='Anuluj'
}
Write-Po 'pl' $keys_pl

# ============================================================================
# PART 2: CANON Audio + Night Env + HUD + Endings
# ============================================================================
Write-Host ''
Write-Host '===== PART 2: CANON Audio + Night Env + HUD + Endings =====' -ForegroundColor Cyan

$gen_audio = @'
#!/usr/bin/env python3
"""gen_audio.py -- THE_LAST_STREETLIGHT audio generator.  stdlib only.

CANON districts (GDD, exactly 11):
  suburbs, residential, park, school, hospital, gas_station, police,
  warehouses, industrial, substation, power_station

Usage: python gen_audio.py <project_root>
Writes 11 distinct music loops + ambient bed + 5 UI sfx into <root>/audio/.
"""
import wave, struct, math, random, os, sys

SR = 22050
PEAK = 0.85

def write_wav(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = PEAK / peak
    frames = bytearray()
    for s in samples:
        v = int(max(-32767, min(32767, s * norm * 32767)))
        frames += struct.pack('<h', v)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("  -> {0} ({1:.1f}s)".format(path, len(samples) / SR))

def midi_to_freq(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)

def env(i, total, a=0.04, r=0.20):
    if total <= 0:
        return 0.0
    t = i / total
    if t < a:
        return t / max(1e-3, a)
    if t > 1.0 - r:
        return max(0.0, (1.0 - t) / max(1e-3, r))
    return 1.0

SCALES = {
    'major':      [0, 2, 4, 5, 7, 9, 11],
    'minor':      [0, 2, 3, 5, 7, 8, 10],
    'pentatonic': [0, 2, 4, 7, 9],
    'mixolydian': [0, 2, 4, 5, 7, 9, 10],
    'phrygdom':   [0, 1, 4, 5, 7, 8, 11],
    'lydian':     [0, 2, 4, 6, 7, 9, 11],
    'blues':      [0, 3, 5, 6, 7, 10],
    'wholetone':  [0, 2, 4, 6, 8, 10],
    'dorian':     [0, 2, 3, 5, 7, 9, 10],
}

DISTRICTS = [
    ('suburbs',       'pentatonic',  90, 60, 14, 0.22, 0.16, 0.10),
    ('residential',   'major',       80, 62, 14, 0.22, 0.14, 0.12),
    ('park',          'lydian',      75, 60, 14, 0.20, 0.12, 0.12),
    ('school',        'major',      100, 64, 14, 0.22, 0.18, 0.10),
    ('hospital',      'wholetone',   60, 54, 10, 0.14, 0.12, 0.10),
    ('gas_station',   'blues',      110, 52, 16, 0.22, 0.18, 0.08),
    ('police',        'minor',      120, 53, 14, 0.18, 0.22, 0.08),
    ('warehouses',    'dorian',      75, 48, 12, 0.14, 0.22, 0.10),
    ('industrial',    'minor',       85, 46, 12, 0.16, 0.24, 0.10),
    ('substation',    'phrygdom',   100, 50, 14, 0.20, 0.20, 0.10),
    ('power_station', 'mixolydian', 105, 55, 14, 0.24, 0.20, 0.12),
]

def synth_lead(freq, dur_s, lead_type='sine'):
    n = int(SR * dur_s)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        e = env(i, n)
        phase = 2 * math.pi * freq * t
        if lead_type == 'sine':
            s = math.sin(phase)
        elif lead_type == 'tri':
            s = 2.0 / math.pi * math.asin(max(-1.0, min(1.0, math.sin(phase))))
        elif lead_type == 'square':
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            s = math.sin(phase) + 0.3 * math.sin(2 * phase)
        out[i] = e * s
    return out

def synth_bass(freq, dur_s):
    n = int(SR * dur_s)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        e = env(i, n, a=0.01, r=0.30)
        phase = 2 * math.pi * freq * t
        s = math.sin(phase)
        if s > 0: s = 1.0
        else: s = -1.0
        out[i] = e * s
    return out

def synth_pad(freq, dur_s):
    n = int(SR * dur_s)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        e = env(i, n, a=0.20, r=0.40)
        phase = 2 * math.pi * freq * t
        s = 0.6 * math.sin(phase) + 0.3 * math.sin(2 * phase) + 0.1 * math.sin(3 * phase)
        out[i] = e * s
    return out

def mix_into(base, add, offset=0, amp=1.0):
    if offset < 0:
        offset = 0
    end = min(len(base), offset + len(add))
    for i in range(offset, end):
        base[i] += amp * add[i - offset]

def gen_district(profile):
    name, scale_name, bpm, root_midi, bars, lead_a, bass_a, pad_a = profile
    scale = SCALES[scale_name]
    beat = 60.0 / bpm
    total_s = beat * 4 * bars
    total_n = int(SR * total_s)
    base = [0.0] * total_n
    rng = random.Random(hash((name, scale_name)) & 0xFFFFFFFF)

    for bar in range(bars):
        deg = rng.choice([0, 0, 4, 5, 3])
        for beat_i in [0, 2]:
            t = (bar * 4 + beat_i) * beat
            midi = (root_midi - 12) + scale[deg % len(scale)]
            if rng.random() < 0.25:
                midi -= 12
            mix_into(base, synth_bass(midi_to_freq(midi), beat * 1.8), int(t * SR), bass_a)

    lead_type = 'sine'
    if scale_name in ('blues', 'phrygdom'):
        lead_type = 'saw'
    elif scale_name in ('wholetone', 'minor'):
        lead_type = 'tri'
    elif scale_name in ('pentatonic', 'lydian'):
        lead_type = 'sine'
    elif scale_name == 'dorian':
        lead_type = 'soft'
    else:
        lead_type = 'sine'
    for bar in range(bars):
        for beat_i in range(4):
            if rng.random() < 0.30:
                continue
            deg = rng.randint(0, len(scale) * 2)
            t = (bar * 4 + beat_i) * beat
            midi = root_midi + scale[deg % len(scale)] + 12 * (deg // len(scale))
            dur = beat * rng.choice([0.5, 1.0, 1.5, 2.0])
            mix_into(base, synth_lead(midi_to_freq(midi), dur, lead_type), int(t * SR), lead_a)

    for bar in range(0, bars, 2):
        chord_deg = rng.choice([0, 3, 4])
        t = bar * 4 * beat
        dur = 4 * beat * 2
        for voice in [0, 4, 7]:
            midi = root_midi + scale[chord_deg % len(scale)] + voice
            mix_into(base, synth_pad(midi_to_freq(midi), dur), int(t * SR), pad_a / 3.0)

    return base

def gen_ambient():
    n = int(SR * 45)
    out = [0.0] * n
    rng = random.Random(2024)
    for layer in range(3):
        f = 55 + layer * 33
        for i in range(n):
            t = i / SR
            e = 0.5 + 0.5 * math.sin(2 * math.pi * 0.07 * t + layer)
            phase = 2 * math.pi * f * t
            s = math.sin(phase) + 0.3 * math.sin(2 * phase)
            out[i] += 0.06 * e * s
    last = 0.0
    for i in range(n):
        w = rng.uniform(-0.02, 0.02)
        last = 0.98 * last + w
        out[i] += last
    return out

def gen_ui(kind):
    if kind == 'click':
        dur, freqs = 0.08, [(880, 0.00, 0.04), (1320, 0.04, 0.04)]
    elif kind == 'hover':
        dur, freqs = 0.06, [(660, 0.00, 0.06)]
    elif kind == 'pickup':
        dur, freqs = [(523, 0.00, 0.05), (784, 0.06, 0.08), (1046, 0.13, 0.10)]
        dur = 0.24
    elif kind == 'deny':
        dur, freqs = [(220, 0.00, 0.05), (165, 0.07, 0.10)]
        dur = 0.18
    elif kind == 'stinger':
        dur = 1.20
        freqs = [(110, 0.00, 0.20), (110, 0.25, 0.20), (87, 0.50, 0.30), (65, 0.80, 0.40)]
    else:
        dur, freqs = 0.10, [(440, 0.00, 0.10)]
    n = int(SR * dur)
    out = [0.0] * n
    for f, t0, t_dur in freqs:
        for i in range(int(t0 * SR), min(int((t0 + t_dur) * SR), n)):
            t = (i - int(t0 * SR)) / SR
            e = math.exp(-4 * t / max(0.05, t_dur))
            phase = 2 * math.pi * f * t
            s = math.sin(phase) + 0.2 * math.sin(2 * phase)
            out[i] += 0.5 * e * s
    return out

def main(out_root):
    print("[gen_audio] SR={0} peak={1}".format(SR, PEAK))
    music_dir = os.path.join(out_root, 'audio', 'music')
    amb_dir   = os.path.join(out_root, 'audio', 'ambient')
    sfx_dir   = os.path.join(out_root, 'audio', 'sfx')
    for d in [music_dir, amb_dir, sfx_dir]:
        os.makedirs(d, exist_ok=True)
    canon_ids = {p[0] for p in DISTRICTS}
    removed = 0
    if os.path.isdir(music_dir):
        for fn in os.listdir(music_dir):
            if fn.lower().endswith('.wav') and fn[:-4] not in canon_ids:
                os.remove(os.path.join(music_dir, fn))
                removed += 1
    if removed > 0:
        print("[gen_audio] purged {0} stale music wavs".format(removed))

    print("[gen_audio] generating 11 CANON district loops:")
    for prof in DISTRICTS:
        name = prof[0]
        samples = gen_district(prof)
        write_wav(os.path.join(music_dir, name + '.wav'), samples)

    print("[gen_audio] generating ambient bed:")
    write_wav(os.path.join(amb_dir, 'ambient.wav'), gen_ambient())

    print("[gen_audio] generating UI sfx:")
    for kind in ['click', 'hover', 'pickup', 'deny']:
        write_wav(os.path.join(sfx_dir, kind + '.wav'), gen_ui(kind))

    print("[gen_audio] generating danger stinger:")
    write_wav(os.path.join(sfx_dir, 'stinger.wav'), gen_ui('stinger'))

    print("[gen_audio] done.  17 files written (11 districts + ambient + 5 sfx).")

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
'@
Write-Utf8 'tools/gen_audio.py' $gen_audio

$audio_rc = Run-Python 'tools/gen_audio.py'
if ($audio_rc -ne 0) {
	Write-Host ('WARN gen_audio.py exited ' + $audio_rc + ' -- continuing')
}

$night_env = @'
extends Node3D
## NightEnv: builds a WorldEnvironment with deep-blue sky, fog, warm glow.
## Per-district tweaks via DistrictThemes (optional).

const SKY_TOP := Color(0.012, 0.020, 0.055)
const SKY_HORIZON := Color(0.085, 0.110, 0.200)
const FOG_TINT := Color(0.040, 0.050, 0.105)
const AMBIENT := Color(0.060, 0.075, 0.130, 1.0)
const MOON_COLOR := Color(0.92, 0.94, 1.00)

var env: WorldEnvironment
var sky: Sky
var moon_light: DirectionalLight3D

func _ready() -> void:
	_build_world_environment()
	_build_moon()
	call_deferred("_apply_district_overrides")

func _build_world_environment() -> void:
	env = WorldEnvironment.new()
	env.name = "NightEnvironment"
	add_child(env)

	var e := env.environment
	if e == null:
		e = Environment.new()
		env.environment = e

	e.background_mode = Environment.BG_SKY
	sky = Sky.new()
	var proc := ProceduralSkyMaterial.new()
	proc.sky_top_color = SKY_TOP
	proc.sky_horizon_color = SKY_HORIZON
	proc.ground_bottom_color = Color(0.015, 0.020, 0.030)
	proc.ground_horizon_color = Color(0.040, 0.050, 0.080)
	proc.sun_angle_max = 30.0
	proc.use_debanding = true
	sky.sky_material = proc
	e.sky = sky

	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 0.4
	e.ambient_light_color = AMBIENT
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 1.2
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_bloom = 0.15
	e.glow_hdr_threshold = 1.0

	e.fog_enabled = true
	e.fog_light_color = FOG_TINT
	e.fog_density = 0.012
	e.fog_aerial_perspective = 0.5

	e.ssao_enabled = false
	e.ssil_enabled = false
	e.ssr_enabled = false

func _build_moon() -> void:
	moon_light = DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_color = MOON_COLOR
	moon_light.light_energy = 0.35
	moon_light.light_indirect_energy = 0.6
	moon_light.shadow_enabled = false
	moon_light.rotation_degrees = Vector3(-55.0, -40.0, 0.0)
	add_child(moon_light)

func _apply_district_overrides() -> void:
	var dt := get_node_or_null("/root/DistrictThemes")
	if dt == null:
		return
	if not dt.has_method("get"):
		return
	var id_val = null
	if "current_id" in dt:
		id_val = dt.current_id
	if id_val == null:
		return
	var d = dt.get(id_val)
	if d == null:
		return
	var e := env.environment
	if e == null:
		return
	if d.has("fog_density"):
		e.fog_density = float(d["fog_density"])
	if d.has("fog_tint"):
		e.fog_light_color = d["fog_tint"]
	if d.has("glow_intensity"):
		e.glow_intensity = float(d["glow_intensity"])
	if d.has("ambient_energy"):
		e.ambient_light_energy = float(d["ambient_energy"])

func set_fog_density(d: float) -> void:
	if env and env.environment:
		env.environment.fog_density = d
'@
Write-Utf8 'scripts/visual/night_env.gd' $night_env

$moon_helper = @'
extends Node3D
## Big procedural moon disc (white sprite quad facing camera).

const RADIUS := 8.0

func _ready() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = SphereMesh.new()
	(mi.mesh as SphereMesh).radius = RADIUS
	(mi.mesh as SphereMesh).height = RADIUS * 2.0
	(mi.mesh as SphereMesh).radial_segments = 24
	(mi.mesh as SphereMesh).rings = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 1.00)
	mat.emission_enabled = true
	mat.emission = Color(0.92, 0.94, 1.00)
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_receive_shadows = true
	mi.material_override = mat
	add_child(mi)
	position = Vector3(60.0, 80.0, -120.0)
'@
Write-Utf8 'scripts/visual/moon_disc.gd' $moon_helper

$window_lights = @'
extends MultiMeshInstance3D
## EmissiveWindows: spawns a MultiMesh of small emissive quads across a wall grid.
## Density per district; warm yellow / cool blue.

const CELL := Vector2(1.6, 2.2)
const WIN_SIZE := Vector2(0.5, 0.7)

@export var cols: int = 16
@export var rows: int = 4
@export var density: float = 0.55
@export var warm_bias: float = 0.75
@export var seed_value: int = 0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.seed = hash(str(global_position) + str(get_path()))
	var count := cols * rows
	multimesh = MultiMesh.new()
	var qm := QuadMesh.new()
	qm.size = WIN_SIZE
	multimesh.mesh = qm
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = false
	multimesh.instance_count = count
	var origin := -Vector3(cols * CELL.x * 0.5, 0.0, 0.0)
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var x := origin.x + (c + 0.5) * CELL.x
			var y := 1.5 + (r + 0.5) * CELL.y
			var t := Transform3D()
			t.origin = Vector3(x, y, 0)
			multimesh.set_instance_transform(idx, t)
			var col: Color
			if _rng.randf() < density:
				if _rng.randf() < warm_bias:
					var v := _rng.randf_range(0.85, 1.0)
					col = Color(v, v * 0.85, v * 0.55)
				else:
					var v := _rng.randf_range(0.55, 0.85)
					col = Color(v * 0.7, v * 0.85, v)
				col = col * _rng.randf_range(1.2, 2.0)
			else:
				col = Color(0.02, 0.025, 0.04)
			multimesh.set_instance_color(idx, col)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_operator = BaseMaterial3D.EMISSION_MULTIPLY
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 1.0
	material_override = mat
'@
Write-Utf8 'scripts/visual/emissive_windows.gd' $window_lights

$hud_panel = @'
extends Control
## HUDPanel: dark translucent rectangle with amber border, optional label.
class_name HUDPanel

@export var w: float = 200.0
@export var h: float = 60.0
@export var border: float = 2.0
@export var radius: float = 4.0
@export var fill_color: Color = Color(0.04, 0.05, 0.08, 0.78)
@export var border_color: Color = Color(1.00, 0.70, 0.28, 0.95)
@export var label: String = ""
@export var label_color: Color = Color(0.96, 0.95, 0.90)
@export var font_size: int = 14

func _ready() -> void:
	custom_minimum_size = Vector2(w, h)
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(w, h))
	draw_rect(Rect2(Vector2(2, 3), Vector2(w, h)), Color(0, 0, 0, 0.45), true)
	draw_rect(r, fill_color, true)
	draw_rect(r, border_color, false, border)
	if label != "":
		var f := ThemeDB.fallback_font
		if f != null:
			var sz := font_size
			var tx := Vector2(10, 8 + sz)
			draw_string(f, tx, label, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, label_color)
'@
Write-Utf8 'scripts/ui/hud_panel.gd' $hud_panel

$hud_minimap = @'
extends Control
## HUDMinimap: circular minimap. Dots for districts, arrow for player, flashlight cone.
class_name HUDMinimap

const RADIUS := 70.0
const CENTER := Vector2(80, 80)
const SIZE := Vector2(160, 160)

@export var districts: Array = []
@export var player_color: Color = Color(1.0, 0.85, 0.4)
@export var dot_color_on: Color = Color(0.3, 1.0, 0.5)
@export var dot_color_off: Color = Color(0.5, 0.5, 0.55)
@export var cone_color: Color = Color(1.0, 0.95, 0.6, 0.18)

var _player_world: Vector3 = Vector3.ZERO
var _player_yaw: float = 0.0
var _flash_dir: Vector2 = Vector2(0, -1)
var _flash_on: bool = false
var _world_min: Vector3 = Vector3(-120, 0, -120)
var _world_max: Vector3 = Vector3(120, 0,  120)

func _ready() -> void:
	custom_minimum_size = SIZE
	queue_redraw()

func set_player(pos: Vector3, yaw_deg: float) -> void:
	_player_world = pos
	_player_yaw = yaw_deg
	queue_redraw()

func set_flash(dir_world: Vector3, on: bool) -> void:
	_flash_on = on
	if dir_world.length() > 0.001:
		_flash_dir = Vector2(dir_world.x, dir_world.z).normalized()
	queue_redraw()

func update_districts(arr: Array) -> void:
	districts = arr
	queue_redraw()

func _world_to_map(w: Vector3) -> Vector2:
	var nx := clamp((w.x - _world_min.x) / max(0.001, _world_max.x - _world_min.x), 0.0, 1.0)
	var ny := clamp((w.z - _world_min.z) / max(0.001, _world_max.z - _world_min.z), 0.0, 1.0)
	return CENTER + Vector2((nx - 0.5) * 2.0 * RADIUS, (ny - 0.5) * 2.0 * RADIUS)

func _draw() -> void:
	draw_circle(CENTER, RADIUS + 4.0, Color(0.04, 0.05, 0.08, 0.78))
	draw_arc(CENTER, RADIUS + 4.0, 0.0, TAU, 64, Color(1.0, 0.70, 0.28, 0.95), 2.0)
	draw_arc(CENTER, RADIUS, 0.0, TAU, 48, Color(0.10, 0.10, 0.14, 0.9), 1.0)
	for d in districts:
		var pos: Vector3 = d.get("pos", Vector3.ZERO)
		var powered: bool = d.get("powered", false)
		var is_current: bool = d.get("current", false)
		var p := _world_to_map(pos)
		var r: float = 4.0 if is_current else 3.0
		var c := dot_color_on if powered else dot_color_off
		if is_current:
			draw_arc(p, 7.0, 0.0, TAU, 16, Color(1.0, 0.85, 0.4, 0.95), 1.5)
		draw_circle(p, r, c)
	if _flash_on:
		draw_circle(CENTER, RADIUS, Color(0, 0, 0, 0.5))
		var fdir := _flash_dir.rotated(-_player_yaw * PI / 180.0)
		var a0 := fdir.angle() - 0.35
		var a1 := fdir.angle() + 0.35
		var pts := PackedVector2Array([
			CENTER,
			CENTER + Vector2(cos(a0), sin(a0)) * RADIUS,
			CENTER + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * RADIUS,
			CENTER + Vector2(cos(a1), sin(a1)) * RADIUS
		])
		draw_colored_polygon(pts, cone_color)
	var pp := _world_to_map(_player_world)
	draw_circle(pp, 3.0, player_color)
	var arr := PackedVector2Array([
		pp + Vector2(0, -5),
		pp + Vector2(-3, 3),
		pp + Vector2(3, 3)
	])
	draw_colored_polygon(arr, player_color)
'@
Write-Utf8 'scripts/ui/hud_minimap.gd' $hud_minimap

$hud_banner = @'
extends Control
## HUDBanner: shows current district name + power progress (0..11 lit districts).
class_name HUDBanner

const W := 280.0
const H := 64.0

@export var district_name: String = "—"
@export var district_localized: String = ""
@export var powered: int = 0
@export var total: int = 11

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	queue_redraw()

func set_district(n: String, loc: String = "") -> void:
	district_name = n
	district_localized = loc
	queue_redraw()

func set_progress(p: int, t: int) -> void:
	powered = p
	total = t
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(W, H))
	draw_rect(Rect2(Vector2(2, 3), Vector2(W, H)), Color(0, 0, 0, 0.45), true)
	draw_rect(r, Color(0.04, 0.05, 0.08, 0.78), true)
	draw_rect(r, Color(1.0, 0.70, 0.28, 0.95), false, 2.0)

	var f := ThemeDB.fallback_font
	if f == null:
		return
	var label := district_localized if district_localized != "" else district_name
	draw_string(f, Vector2(12, 22), "▶ " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.85, 0.5))

	var bar_x := 12.0
	var bar_y := 38.0
	var bar_w := W - 24.0
	var bar_h := 14.0
	draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(bar_w, bar_h)), Color(0.10, 0.10, 0.15), true)
	draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(bar_w, bar_h)), Color(1.0, 0.70, 0.28, 0.8), false, 1.0)
	var pct := clamp(float(powered) / max(1, total), 0.0, 1.0)
	draw_rect(Rect2(Vector2(bar_x + 2, bar_y + 2), Vector2((bar_w - 4) * pct, bar_h - 4)), Color(1.0, 0.85, 0.4), true)

	draw_string(f, Vector2(W - 60, 22), "%d / %d" % [powered, total], HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color(0.95, 0.95, 0.95))
'@
Write-Utf8 'scripts/ui/hud_banner.gd' $hud_banner

$hud_main = @'
extends CanvasLayer
## HUDMain: composes banner + minimap + lives + coins + battery.
## Null-safe reads of PowerGrid / SaveLoad / Player.  No autoload order deps.

const PANEL_AMBER := Color(1.00, 0.70, 0.28, 0.95)
const PANEL_FILL := Color(0.04, 0.05, 0.08, 0.78)

var banner: Control
var minimap: Control
var lives_label: Label
var coins_label: Label
var battery_bar: Panel
var _banner_script: Script
var _minimap_script: Script

func _ready() -> void:
	layer = 10
	_banner_script = load("res://scripts/ui/hud_banner.gd")
	_minimap_script = load("res://scripts/ui/hud_minimap.gd")
	_build_panels()
	call_deferred("_initial_pull")

func _build_panels() -> void:
	if _banner_script != null:
		banner = _banner_script.new()
		banner.position = Vector2(16, 16)
		add_child(banner)

	var lives_panel := _make_panel(Vector2(1100, 16), Vector2(160, 56))
	lives_label = Label.new()
	lives_label.position = Vector2(12, 6)
	lives_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	lives_label.text = "♥ ♥ ♥"
	lives_label.add_theme_font_size_override("font_size", 24)
	lives_panel.add_child(lives_label)
	add_child(lives_panel)

	var coins_panel := _make_panel(Vector2(1080, 620), Vector2(180, 80))
	coins_label = Label.new()
	coins_label.position = Vector2(12, 8)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	coins_label.text = "● 0"
	coins_label.add_theme_font_size_override("font_size", 28)
	coins_panel.add_child(coins_label)
	add_child(coins_panel)

	var batt_panel := _make_panel(Vector2(560, 660), Vector2(160, 40))
	battery_bar = _make_panel(Vector2(8, 14), Vector2(144, 12))
	battery_bar.modulate = Color(1.0, 0.85, 0.3)
	batt_panel.add_child(battery_bar)
	add_child(batt_panel)

	if _minimap_script != null:
		minimap = _minimap_script.new()
		minimap.position = Vector2(16, 530)
		add_child(minimap)

func _make_panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.custom_minimum_size = size
	var st := StyleBoxFlat.new()
	st.bg_color = PANEL_FILL
	st.border_color = PANEL_AMBER
	st.set_border_width_all(2)
	st.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", st)
	return p

func _initial_pull() -> void:
	_refresh_power()
	_refresh_district()
	_refresh_lives()
	_refresh_coins()

func _process(_delta: float) -> void:
	_refresh_power()
	_refresh_district()
	_refresh_lives()
	_refresh_coins()
	_refresh_player()
	_refresh_battery()

func _get_node(s: String) -> Node:
	return get_tree().root.get_node_or_null(s)

func _refresh_power() -> void:
	var pg := _get_node("PowerGrid")
	if pg == null or not pg.has_method("get_progress"):
		return
	var prog: Dictionary = pg.get_progress()
	if banner != null and banner.has_method("set_progress"):
		banner.set_progress(int(prog.get("powered", 0)), int(prog.get("total", 11)))

func _refresh_district() -> void:
	var dt := _get_node("DistrictThemes")
	if dt == null:
		return
	var cur: String = "—"
	if dt.has_method("current_id"):
		cur = String(dt.current_id)
	if banner != null and banner.has_method("set_district"):
		var loc_key := "hud_district"
		var i18n := _get_node("I18n")
		var loc: String = loc_key
		if i18n != null and i18n.has_method("t"):
			loc = i18n.t(loc_key)
		banner.set_district(cur, "%s: %s" % [loc, cur.capitalize()])

func _refresh_lives() -> void:
	var sl := _get_node("SaveLoad")
	if sl == null or not sl.has_method("get_lives"):
		return
	var lives: int = int(sl.get_lives())
	var hearts := ""
	for i in range(max(0, lives)):
		hearts += "♥ "
	if lives_label != null:
		lives_label.text = hearts.strip_edges()

func _refresh_coins() -> void:
	var sl := _get_node("SaveLoad")
	if sl == null or not sl.has_method("get_coins"):
		return
	var coins: int = int(sl.get_coins())
	if coins_label != null:
		coins_label.text = "● %d" % coins

func _refresh_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or minimap == null:
		return
	if minimap.has_method("set_player"):
		minimap.set_player(p.global_position, 0.0)
	if minimap.has_method("set_flash") and p.has_method("get_flashlight_dir"):
		var d: Vector3 = p.get_flashlight_dir()
		minimap.set_flash(d, p.has_method("is_flashlight_on") and p.is_flashlight_on())

func _refresh_battery() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or battery_bar == null:
		return
	if not p.has_method("get_battery"):
		return
	var b: float = clamp(p.get_battery(), 0.0, 1.0)
	battery_bar.custom_minimum_size = Vector2(144.0 * b, 12.0)
	if b < 0.20:
		battery_bar.modulate = Color(1.0, 0.3, 0.3)
	elif b < 0.50:
		battery_bar.modulate = Color(1.0, 0.7, 0.3)
	else:
		battery_bar.modulate = Color(1.0, 0.95, 0.5)
'@
Write-Utf8 'scripts/ui/hud_main.gd' $hud_main

$ending_screen = @'
extends CanvasLayer
## EndingScreen: shown when game ends.  kind = "win" | "lose".
## Self-dismisses on input; advances SaveLoad.ending_shown.

const COLOR_WIN_BG := Color(0.02, 0.05, 0.10, 0.92)
const COLOR_LOSE_BG := Color(0.10, 0.02, 0.04, 0.92)
const COLOR_AMBER := Color(1.0, 0.75, 0.30)
const COLOR_TEXT := Color(0.96, 0.95, 0.90)

@export var kind: String = "win"
var _bg: ColorRect
var _title: Label
var _sub: Label
var _hint: Label
var _tween: Tween

func _ready() -> void:
	layer = 100
	_build()

func show_ending(k: String) -> void:
	kind = k
	if _bg == null:
		_build()
	_apply_kind()

func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = COLOR_WIN_BG
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.modulate.a = 0.0
	add_child(_bg)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", COLOR_AMBER)
	box.add_child(_title)

	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 22)
	_sub.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(_sub)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_hint.text = "[ESC]  /  [TAP]"
	box.add_child(_hint)

	_apply_kind()
	_tween = create_tween()
	_tween.tween_property(_bg, "modulate:a", 1.0, 1.2)

func _apply_kind() -> void:
	if _title == null:
		return
	var key_title: StringName = &"msg_win" if kind == "win" else &"msg_lose"
	var key_msg: StringName = &"msg_win" if kind == "win" else &"msg_lose"
	if Engine.has_singleton("I18n") or get_tree().root.get_node_or_null("I18n") != null:
		var i18n := get_tree().root.get_node_or_null("I18n")
		if i18n != null and i18n.has_method("t"):
			_title.text = i18n.t(key_title)
			_sub.text = i18n.t(key_msg)
		else:
			_title.text = "ALL DISTRICTS POWERED!" if kind == "win" else "YOU FAILED..."
			_sub.text = _title.text
	else:
		_title.text = "ALL DISTRICTS POWERED!" if kind == "win" else "YOU FAILED..."
		_sub.text = _title.text
	if _bg != null:
		_bg.color = COLOR_WIN_BG if kind == "win" else COLOR_LOSE_BG

func _unhandled_input(event: InputEvent) -> void:
	if _tween != null and _tween.is_running():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventScreenTouch and event.pressed):
		var sl := get_tree().root.get_node_or_null("SaveLoad")
		if sl != null and sl.has_method("mark_ending_shown"):
			sl.mark_ending_shown()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
'@
Write-Utf8 'scripts/ui/ending_screen.gd' $ending_screen

# ============================================================================
# PART 3: Gameplay Systems + LAN + Scene Wiring
# ============================================================================
Write-Host ''
Write-Host '===== PART 3: Gameplay Systems + LAN + Scene Wiring =====' -ForegroundColor Cyan

Ensure-Dir 'scripts/events'
Ensure-Dir 'scripts/world'
Ensure-Dir 'scripts/net'
Ensure-Dir 'scenes/districts'

$event_bus = @'
extends Node
## Autoload "EventBus".  Signal hub.  No order deps; no _ready work.

signal district_entered(district_id: StringName)
signal district_powered(district_id: StringName)
signal coin_changed(amount: int)
signal lives_changed(amount: int)
signal flashlight_toggled(on: bool)
signal player_caught
signal game_saved
signal game_loaded
signal shop_purchased(item: StringName)
signal remote_player_state(peer_id: int, pos: Vector3, yaw: float, district: StringName)
signal remote_power_changed(district: StringName, powered: bool)
signal lan_hosted(port: int)
signal lan_joined(peer_id: int)
signal lan_disconnected

func emit_district_entered(d: StringName) -> void:
	district_entered.emit(d)

func emit_district_powered(d: StringName) -> void:
	district_powered.emit(d)

func emit_coin(c: int) -> void:
	coin_changed.emit(c)

func emit_lives(l: int) -> void:
	lives_changed.emit(l)
'@
Write-Utf8 'scripts/events/event_bus.gd' $event_bus
Add-Autoload 'EventBus' 'res://scripts/events/event_bus.gd'

$save_load = @'
extends Node
## Autoload "SaveLoad".  Coins, lives, powered districts, current district.
## Auto-saves on district_entered / pause / game_saved signal.

const SAVE_PATH := "user://saves/save_0.json"
const MAX_LIVES := 3

var coins: int = 0
var lives: int = MAX_LIVES
var powered: Dictionary = {}
var current_district: StringName = &""
var flashlight_battery: float = 1.0
var player_position: Vector3 = Vector3.ZERO
var _ending_shown: bool = false
var _bus: Node

func _ready() -> void:
	_ensure_save_dir()
	_bus = get_node_or_null("/root/EventBus")
	if _bus != null:
		_bus.district_entered.connect(_on_district_entered)
		_bus.game_saved.connect(_on_game_saved)
		_bus.shop_purchased.connect(_on_shop_purchased)
		_bus.player_caught.connect(_on_player_caught)
	if FileAccess.file_exists(SAVE_PATH):
		load_game()

func _ensure_save_dir() -> void:
	var d := DirAccess.open("user://")
	if d != null and not d.dir_exists("saves"):
		d.make_dir_recursive("saves")

func _on_district_entered(d: StringName) -> void:
	current_district = d
	save_game()

func _on_game_saved() -> void:
	save_game()

func _on_shop_purchased(item: StringName) -> void:
	if item == &"medkit":
		lives = min(MAX_LIVES, lives + 1)
		if _bus != null:
			_bus.emit_lives(lives)
	elif item == &"battery":
		flashlight_battery = min(1.0, flashlight_battery + 0.25)
	elif item == &"stamina":
		pass
	save_game()

func _on_player_caught() -> void:
	lives = max(0, lives - 1)
	if _bus != null:
		_bus.emit_lives(lives)
	if lives <= 0:
		var sl := get_tree().root.get_node_or_null("SaveLoad")
		if sl != null:
			sl._ending_shown = true
		var es := get_tree().root.get_node_or_null("EndingScreen")
		if es == null:
			es = load("res://scripts/ui/ending_screen.gd").new()
			get_tree().root.add_child(es)
		if es.has_method("show_ending"):
			es.show_ending("lose")
	save_game()

func get_lives() -> int: return lives
func get_coins() -> int: return coins
func is_powered(d: StringName) -> bool: return powered.get(d, false)
func mark_ending_shown() -> void: _ending_shown = true

func set_coins(c: int) -> void:
	coins = max(0, c)
	if _bus != null:
		_bus.emit_coin(coins)

func add_coins(c: int) -> void:
	set_coins(coins + c)

func set_powered(d: StringName, v: bool) -> void:
	powered[d] = v
	if v and _bus != null:
		_bus.emit_district_powered(d)
	save_game()

func save_game() -> void:
	_ensure_save_dir()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[SaveLoad] cannot open save for write")
		return
	var data := {
		"coins": coins,
		"lives": lives,
		"powered": powered,
		"current_district": String(current_district),
		"flashlight_battery": flashlight_battery,
		"player_position": [player_position.x, player_position.y, player_position.z],
		"ending_shown": _ending_shown
	}
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	coins = int(data.get("coins", 0))
	lives = int(data.get("lives", MAX_LIVES))
	powered = data.get("powered", {})
	current_district = StringName(String(data.get("current_district", "")))
	flashlight_battery = float(data.get("flashlight_battery", 1.0))
	var pp = data.get("player_position", [0, 0, 0])
	if pp is Array and pp.size() >= 3:
		player_position = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
	_ending_shown = bool(data.get("ending_shown", false))
	if _bus != null:
		_bus.emit_coin(coins)
		_bus.emit_lives(lives)
	return true

func reset() -> void:
	coins = 0
	lives = MAX_LIVES
	powered = {}
	current_district = &""
	flashlight_battery = 1.0
	player_position = Vector3.ZERO
	_ending_shown = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
'@
Write-Utf8 'scripts/save_load.gd' $save_load
Add-Autoload 'SaveLoad' 'res://scripts/save_load.gd'

$power_grid = @'
extends Node
## Autoload "PowerGrid".  Owns 11 district power states.

const CANON_IDS: PackedStringArray = [
	"suburbs", "residential", "park", "school", "hospital",
	"gas_station", "police", "warehouses", "industrial",
	"substation", "power_station"
]

var _powered: Dictionary = {}

func _ready() -> void:
	var sl := get_node_or_null("/root/SaveLoad")
	if sl != null and sl.has_method("is_powered"):
		for id in CANON_IDS:
			_powered[id] = sl.is_powered(StringName(id))
	else:
		for id in CANON_IDS:
			_powered[id] = false

func toggle_district(id: StringName) -> bool:
	var key := String(id)
	if not CANON_IDS.has(key):
		push_warning("[PowerGrid] unknown district " + key)
		return false
	_powered[key] = not bool(_powered[key])
	var sl := get_node_or_null("/root/SaveLoad")
	if sl != null and sl.has_method("set_powered"):
		sl.set_powered(StringName(key), _powered[key])
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and _powered[key]:
		bus.emit_district_powered(StringName(key))
	_check_win()
	return _powered[key]

func is_powered(id: StringName) -> bool:
	return bool(_powered.get(String(id), false))

func powered_count() -> int:
	var n := 0
	for id in CANON_IDS:
		if _powered.get(id, false):
			n += 1
	return n

func total_count() -> int:
	return CANON_IDS.size()

func get_progress() -> Dictionary:
	return {"powered": powered_count(), "total": total_count()}

func _check_win() -> void:
	if powered_count() < total_count():
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.emit_district_powered(&"__all__")
	var sl := get_node_or_null("/root/SaveLoad")
	if sl != null:
		sl._ending_shown = true
	var es := get_tree().root.get_node_or_null("EndingScreen")
	if es == null:
		var EScript := load("res://scripts/ui/ending_screen.gd")
		if EScript != null:
			es = EScript.new()
			es.name = "EndingScreen"
			get_tree().root.add_child(es)
	if es != null and es.has_method("show_ending"):
		es.show_ending("win")
'@
Write-Utf8 'scripts/power_grid.gd' $power_grid
Add-Autoload 'PowerGrid' 'res://scripts/power_grid.gd'

$power_switch = @'
extends Node3D
## PowerSwitch: visible panel with OmniLight3D. Toggle PowerGrid on interact.

@export var district_id: StringName = &""
@export var locked: bool = false

var _panel: MeshInstance3D
var _light: OmniLight3D
var _label: Label3D
var _bus: Node

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	_build_visual()
	call_deferred("_refresh_visual")

func _build_visual() -> void:
	_panel = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 1.6, 0.2)
	_panel.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 0.4
	_panel.material_override = mat
	add_child(_panel)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.7, 0.3)
	_light.light_energy = 0.0
	_light.omni_range = 6.0
	_light.position = Vector3(0, 0.6, 0.6)
	add_child(_light)

	_label = Label3D.new()
	_label.text = String(district_id).to_upper()
	_label.font_size = 32
	_label.position = Vector3(0, 1.8, 0.1)
	_label.modulate = Color(1.0, 0.85, 0.4)
	add_child(_label)

func _refresh_visual() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	var on: bool = pg.is_powered(district_id)
	_light.light_energy = 1.5 if on else 0.0
	var mat := _panel.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = 1.5 if on else 0.2
	if _bus != null and not _bus.district_powered.is_connected(_refresh_visual):
		_bus.district_powered.connect(_refresh_visual)

func interact(player: Node) -> void:
	if locked:
		return
	if district_id == &"":
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	pg.toggle_district(district_id)
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 2.5, 0.08)
	tw.tween_property(_light, "light_energy", 1.5 if pg.is_powered(district_id) else 0.0, 0.35)
'@
Write-Utf8 'scripts/world/power_switch.gd' $power_switch

$shop = @'
extends Node3D
## Shop: interactable vendor NPC + UI panel for battery/medkit/stamina.

const ITEMS := [
	{"id": "battery", "key": "shop_battery", "cost":  50},
	{"id": "medkit",  "key": "shop_medkit",  "cost": 100},
	{"id": "stamina", "key": "shop_stamina", "cost":  75}
]

var _ui: CanvasLayer
var _bus: Node
var _sl: Node

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	_sl = get_node_or_null("/root/SaveLoad")

func interact(player: Node) -> void:
	if _ui == null:
		_build_ui()
	_ui.visible = true

func close() -> void:
	if _ui != null:
		_ui.visible = false

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 50
	add_child(_ui)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_ui.add_child(bg)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_ui.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for it in ITEMS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)

		var name_l := Label.new()
		name_l.custom_minimum_size = Vector2(220, 0)
		var i18n := get_node_or_null("/root/I18n")
		if i18n != null and i18n.has_method("t"):
			name_l.text = i18n.t(StringName(it["key"]))
		else:
			name_l.text = it["id"]
		name_l.add_theme_font_size_override("font_size", 18)
		name_l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		row.add_child(name_l)

		var cost_l := Label.new()
		cost_l.text = "● %d" % int(it["cost"])
		cost_l.add_theme_font_size_override("font_size", 18)
		cost_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		row.add_child(cost_l)

		var btn := Button.new()
		btn.text = "BUY"
		btn.pressed.connect(_on_buy.bind(it["id"], int(it["cost"])))
		row.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	box.add_child(close_btn)

func _on_buy(item_id: String, cost: int) -> void:
	if _sl == null or not _sl.has_method("get_coins"):
		return
	if int(_sl.get_coins()) < cost:
		return
	_sl.add_coins(-cost)
	if _bus != null:
		_bus.shop_purchased.emit(StringName(item_id))

func _on_close() -> void:
	close()
'@
Write-Utf8 'scripts/world/shop.gd' $shop

$district_trigger = @'
extends Area3D
## DistrictTrigger: placed in each district scene; emits district_entered on body enter.

@export var district_id: StringName = &""
@export var one_shot: bool = false

var _bus: Node
var _fired: bool = false

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if one_shot and _fired:
		return
	if not b.is_in_group("player"):
		return
	if district_id == &"":
		return
	_fired = true
	if _bus != null and _bus.has_method("emit_district_entered"):
		_bus.emit_district_entered(district_id)
	else:
		print("[DistrictTrigger] entered: ", district_id)
'@
Write-Utf8 'scripts/world/district_trigger.gd' $district_trigger

$lan_network = @'
extends Node
## Autoload "LANNetwork".  ENet host/join + rpc state sync.

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 4

enum Role { OFFLINE, HOST, CLIENT }
var role: int = Role.OFFLINE
var connected: bool = false
var _peer: ENetMultiplayerPeer

func host(port: int = DEFAULT_PORT) -> int:
	leave()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_warning("[LAN] host failed err=%d" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	role = Role.HOST
	connected = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_hosted.emit(port)
	return OK

func join(host_ip: String, port: int = DEFAULT_PORT) -> int:
	leave()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(host_ip, port)
	if err != OK:
		push_warning("[LAN] join failed err=%d" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	role = Role.CLIENT
	connected = true
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE
	connected = false
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_disconnected.emit()

func is_host() -> bool: return role == Role.HOST
func is_client() -> bool: return role == Role.CLIENT
func is_online() -> bool: return connected

func _on_peer_connected(id: int) -> void:
	print("[LAN] peer connected ", id)
func _on_peer_disconnected(id: int) -> void:
	print("[LAN] peer disconnected ", id)
func _on_connected_to_server() -> void:
	print("[LAN] connected to server")
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.lan_joined.emit(multiplayer.get_unique_id())
func _on_connection_failed() -> void:
	print("[LAN] connection failed")
	leave()
func _on_server_disconnected() -> void:
	print("[LAN] server disconnected")
	leave()

@rpc("any_peer", "call_local", "unreliable")
func rpc_player_state(peer_id: int, pos: Vector3, yaw: float, district: StringName) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.remote_player_state.emit(peer_id, pos, yaw, district)

@rpc("any_peer", "call_local", "reliable")
func rpc_power_changed(district: StringName, powered: bool) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.remote_power_changed.emit(district, powered)

func broadcast_player_state(pos: Vector3, yaw: float, district: StringName) -> void:
	if not connected:
		return
	rpc_player_state.rpc(multiplayer.get_unique_id(), pos, yaw, district)

func broadcast_power(district: StringName, powered: bool) -> void:
	if not connected:
		return
	rpc_power_changed.rpc(district, powered)
'@
Write-Utf8 'scripts/net/lan_network.gd' $lan_network
Add-Autoload 'LANNetwork' 'res://scripts/net/lan_network.gd'

$lan_menu = @'
extends CanvasLayer
## LANMenu: minimal host/join form.

var _root: Control
var _bus: Node

func _ready() -> void:
	layer = 60
	_bus = get_node_or_null("/root/EventBus")
	_build()
	visible = false

func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_root.add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(440, 220)
	box.add_theme_constant_override("separation", 16)
	_root.add_child(box)
	var title := Label.new()
	title.text = "LAN"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(title)
	var host_btn := Button.new()
	host_btn.text = "Host"
	host_btn.pressed.connect(_on_host)
	box.add_child(host_btn)
	var ip_edit := LineEdit.new()
	ip_edit.placeholder_text = "host ip (e.g. 192.168.1.10)"
	ip_edit.custom_minimum_size = Vector2(400, 0)
	box.add_child(ip_edit)
	var join_btn := Button.new()
	join_btn.text = "Join"
	join_btn.pressed.connect(_on_join.bind(ip_edit))
	box.add_child(join_btn)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): visible = false)
	box.add_child(close_btn)

func _on_host() -> void:
	var lan := get_node_or_null("/root/LANNetwork")
	if lan != null and lan.has_method("host"):
		var r = lan.host()
		if r == OK:
			visible = false

func _on_join(edit: LineEdit) -> void:
	var lan := get_node_or_null("/root/LANNetwork")
	if lan == null or not lan.has_method("join"):
		return
	var ip := edit.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var r = lan.join(ip)
	if r == OK:
		visible = false

func toggle() -> void:
	visible = not visible
'@
Write-Utf8 'scripts/net/lan_menu.gd' $lan_menu

$enemy_ai = @'
extends CharacterBody3D
class_name EnemyLightAI
## Light-aware enemy. Bolder in dark, cautious in light, runs from flashlight.

@export var move_speed: float = 2.5
@export var patrol_speed: float = 1.2
@export var flee_speed: float = 4.5
@export var detection_range: float = 12.0
@export var dark_boost: float = 1.5
@export var catch_distance: float = 1.2

enum State { PATROL, CHASE, FLEE }

var _state: int = State.PATROL
var _player: Node3D
var _patrol: Array = []
var _patrol_i: int = 0
var _light_grid: Node

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_collect_patrol()
	_light_grid = get_node_or_null("/root/LightGrid")
	set_physics_process(true)

func _collect_patrol() -> void:
	_patrol.clear()
	for n in get_tree().get_nodes_in_group("patrol"):
		_patrol.append((n as Node3D).global_position)
	if _patrol.is_empty():
		_patrol.append(global_position)

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_p: Vector3 = _player.global_position - global_position
	var dist: float = to_p.length()
	var lit: bool = _grid_is_lit(global_position, 0.25)
	var br: float = _grid_brightness(global_position)
	var det: float = detection_range * (dark_boost if not lit else 1.0)
	var flash_pos := Vector3.ZERO
	var flash_dist := -1.0
	var nearest = _grid_nearest_flashlight(global_position)
	if nearest is Array and nearest.size() >= 2:
		flash_pos = nearest[0]
		flash_dist = float(nearest[1])

	var near_flash := flash_dist >= 0.0 and flash_dist < 6.0
	if near_flash:
		_set_state(State.FLEE)
	elif dist < det and not lit:
		_set_state(State.CHASE)
	elif dist < det * 0.5 and lit:
		_set_state(State.CHASE)
	else:
		_set_state(State.PATROL)

	match _state:
		State.PATROL:
			_tick_patrol()
		State.CHASE:
			_tick_chase(br)
		State.FLEE:
			_tick_flee(flash_pos, to_p)

func _set_state(s: int) -> void:
	if s == _state:
		return
	_state = s

func _tick_patrol() -> void:
	if _patrol.is_empty():
		return
	var t: Vector3 = _patrol[_patrol_i]
	_move(t, patrol_speed)
	if global_position.distance_to(t) < 1.5:
		_patrol_i = (_patrol_i + 1) % _patrol.size()

func _tick_chase(br: float) -> void:
	var sp: float = move_speed * (1.4 if br < 0.2 else 0.6)
	_move(_player.global_position, sp)

func _tick_flee(flash_pos: Vector3, to_p: Vector3) -> void:
	var away: Vector3 = global_position - flash_pos
	if away.length() < 0.1:
		away = -to_p
	_move(global_position + away.normalized() * 5.0, flee_speed)

func _move(target: Vector3, speed: float) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	velocity = dir.normalized() * speed
	move_and_slide()

func state_name() -> StringName:
	match _state:
		State.PATROL:
			return &"PATROL"
		State.CHASE:
			return &"CHASE"
		State.FLEE:
			return &"FLEE"
	return &"?"

func caught_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) < catch_distance

func _grid_is_lit(p: Vector3, radius: float) -> bool:
	if _light_grid == null:
		return false
	if _light_grid.has_method("is_lit"):
		return bool(_light_grid.is_lit(p, radius))
	return false

func _grid_brightness(p: Vector3) -> float:
	if _light_grid == null:
		return 0.0
	if _light_grid.has_method("cell_brightness"):
		return float(_light_grid.cell_brightness(p))
	return 0.0

func _grid_nearest_flashlight(p: Vector3):
	if _light_grid == null:
		return null
	if _light_grid.has_method("nearest_flashlight"):
		return _light_grid.nearest_flashlight(p)
	return null
'@
Write-Utf8 'scripts/enemy/enemy_light_ai.gd' $enemy_ai

$scene_patcher = @'
#!/usr/bin/env python3
"""patch_scenes.py -- scene wiring (idempotent)."""
import os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."

MAIN_SCENE = "scenes/main_3d.tscn"
DISTRICT_DIR = "scenes/districts"
CANON_DISTRICTS = [
    "suburbs", "residential", "park", "school", "hospital",
    "gas_station", "police", "warehouses", "industrial",
    "substation", "power_station"
]

EXT_RES = [
    ("res://scripts/visual/night_env.gd",      "NightEnvScript"),
    ("res://scripts/ui/hud_main.gd",           "HUDScript"),
    ("res://scripts/ui/ending_screen.gd",      "EndingScript"),
    ("res://scripts/net/lan_menu.gd",          "LANMenuScript"),
    ("res://scripts/world/power_switch.gd",    "PowerSwitchScript"),
    ("res://scripts/world/district_trigger.gd","DistrictTriggerScript"),
    ("res://scripts/visual/emissive_windows.gd","EmissiveWindowsScript"),
]

def patch_main(path):
    if not os.path.isfile(path):
        print("[patch] main scene missing: " + path)
        return
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    changed = False
    for rp, hint in EXT_RES:
        if rp in text:
            continue
        ids = [int(m.group(1)) for m in re.finditer(r'id="(\d+)_([A-Za-z0-9]+)"', text)]
        max_id = max(ids) if ids else 0
        new_id = "%d_%s" % (max_id + 1, hint[:6])
        block = '[ext_resource type="Script" path="' + rp + '" id="' + new_id + '"]\n'
        idx = text.find("[node ")
        if idx < 0:
            text += block
        else:
            text = text[:idx] + block + text[idx:]
        changed = True
        print("[patch] main: ext_resource " + rp)

    def add_node(name, parent_attr, type_str, ext_id_hint, extra=""):
        nonlocal text, changed
        if '[node name="' + name + '"' in text:
            return
        m = re.search(r'id="(\d+_' + re.escape(ext_id_hint[:6]) + r')"
        eid = m.group(1)
        block = ("\n[node name=\"" + name + "\" type=\"" + type_str + "\" parent=\"" + parent_attr + "\"]\n"
                 + ("script = ExtResource(\"" + eid + "\")\n" if ext_id_hint else "")
                 + extra)
        text += block
        changed = True
        print("[patch] " + district_id + ": node " + name)

    add_node("PowerSwitch",        ".", "Node3D",            "PowerSwitchScript",
             "district_id = \"" + district_id + "\"\n")
    add_node("DistrictTrigger",    ".", "Area3D",            "DistrictTriggerScript",
             "district_id = \"" + district_id + "\"\n")
    add_node("EmissiveWindows",    ".", "MultiMeshInstance3D","EmissiveWindowsScript",
             "seed_value = " + str(abs(hash(district_id)) % 99999) + "\n")

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print("[patch] " + district_id + " saved")

def main(root):
    print("[patch] root=" + root)
    patch_main_path = os.path.join(root, MAIN_SCENE)
    patch_main(patch_main_path)
    ddir = os.path.join(root, DISTRICT_DIR)
    if not os.path.isdir(ddir):
        os.makedirs(ddir, exist_ok=True)
        print("[patch] created " + DISTRICT_DIR)
    for did in CANON_DISTRICTS:
        dp = os.path.join(ddir, did + ".tscn")
        patch_district(dp, did)
    print("[patch] done.")

if __name__ == "__main__":
    main(ROOT)
'@
Write-Utf8 'tools/patch_scenes.py' $scene_patcher

$patch_rc = Run-Python 'tools/patch_scenes.py'
if ($patch_rc -ne 0) {
	Write-Host ('WARN patch_scenes.py exited ' + $patch_rc + ' -- continuing')
}

# ============================================================================
# PART 4: Android Export + Compile Gate + Smoke + Git
# ============================================================================
Write-Host ''
Write-Host '===== PART 4: Android Export + Compile Gate + Smoke + Git =====' -ForegroundColor Cyan

Ensure-Dir 'scenes/tools'
Ensure-Dir 'scripts/tools'

$android_preset = @'
[preset.0]

name="Android"
platform="Android"
runnable=true
export_filter="all_resources"
export_path="build/TLS.apk"

[preset.0.options]

architectures/arm64-v8a=true
architectures/armeabi-v7a=false
version/code=1
version/name="1.0"
package/unique_name="com.tls.game"
package/name="TLS"
package/signed=true
graphics/opengl_debug=false
screen/immersive_mode=true
'@
Write-Utf8 'export_presets.cfg' $android_preset

$keystore = Join-Path $root 'tls-debug.keystore'
if (-not (Test-Path $keystore)) {
	$keytool = Get-Command 'keytool' -ErrorAction SilentlyContinue
	if ($keytool) {
		Write-Host 'GENKEY  tls-debug.keystore'
		& keytool -genkeypair -v -keystore $keystore -storetype PKCS12 `
			-storepass tlsdebug -keypass tlsdebug `
			-keyalg RSA -keysize 2048 -validity 10950 `
			-alias tlsdebug -dname "CN=TLS, OU=Game, O=TLS, L=NA, ST=NA, C=US" 2>&1 | Out-Null
	}
}

$bootstrap_final = @'
extends Node
const ONE_SHOT_KEY := "_tls_bootstrapped"

func _enter_tree() -> void:
	if Engine.has_meta(ONE_SHOT_KEY):
		return
	Engine.set_meta(ONE_SHOT_KEY, true)
	print("[_Bootstrap] final bootstrap")

func _wire_signals() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	for sig in ["district_entered", "power_state_changed", "coin_collected", "player_died", "shop_purchase"]:
		if not bus.has_signal(sig):
			bus.add_user_signal(sig)
'@
Write-Utf8 '_bootstrap.gd' $bootstrap_final
Add-Autoload '_Bootstrap' '*_bootstrap.gd'

$compile_runner = @'
extends Node
const BAD := []

func _ready() -> void:
	_parse_dir("res://scripts")
	if BAD.is_empty():
		print("COMPILE: БЕЗ ОШИБОК")
		get_tree().quit(0)
	else:
		print("COMPILE: BAD:")
		for e in BAD:
			print("  - " + e)
		get_tree().quit(2)

func _parse_dir(d: String) -> void:
	var dir := DirAccess.open(d)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var p := d + "/" + name
		if dir.current_is_dir():
			if not name.begins_with("."):
				_parse_dir(p)
		elif name.ends_with(".gd"):
			_check_gd(p)
		name = dir.get_next()
	dir.list_dir_end()

func _check_gd(p: String) -> void:
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		BAD.append(p + ": cannot open")
		return
	var txt := f.get_as_text()
	f.close()
	var script := GDScript.new()
	script.source_code = txt
	var err := script.reload()
	if err != OK:
		BAD.append(p + ": parse error")
'@
Write-Utf8 'scripts/tools/compile_runner.gd' $compile_runner

$compile_scene = @'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/tools/compile_runner.gd" id="1_runner"]
[node name="CompileRunner" type="Node"]
script = ExtResource("1_runner")
'@
Write-Utf8 'scenes/tools/compile_scene.tscn' $compile_scene

function Invoke-Godot([string[]]$args) {
	$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
	if (-not (Test-Path $godot)) {
		$cmd = Get-Command 'godot' -ErrorAction SilentlyContinue
		if ($cmd) { $godot = $cmd.Source }
	}
	if (-not (Test-Path $godot)) {
		Write-Host 'WARN godot not found -- skipping gate'
		return 'NO_GODOT'
	}
	$full = @('--path', $root) + $args
	Write-Host ('GODOT  ' + ($full -join ' '))
	$proc = Start-Process -FilePath $godot -ArgumentList $full -NoNewWindow -PassThru -Wait `
		-RedirectStandardError 'stderr.tmp' -RedirectStandardOutput 'stdout.tmp'
	$out = ""
	if (Test-Path 'stdout.tmp') { $out += [System.IO.File]::ReadAllText('stdout.tmp', $utf8) }
	if (Test-Path 'stderr.tmp') { $out += [System.IO.File]::ReadAllText('stderr.tmp', $utf8) }
	Remove-Item 'stdout.tmp','stderr.tmp' -ErrorAction SilentlyContinue
	return $out
}

Write-Host '====== HEADLESS COMPILE GATE ======'
$compileOut = Invoke-Godot @('--headless', 'res://scenes/tools/compile_scene.tscn')
if ($compileOut -match 'БЕЗ ОШИБОК') {
	$script:CompileStatus = 'PASS'
	Write-Host 'COMPILE: БЕЗ ОШИБОК' -ForegroundColor Green
} else {
	$script:CompileStatus = 'FAIL'
	Write-Host 'COMPILE: BAD' -ForegroundColor Red
	Write-Host $compileOut
}

Write-Host '====== SMOKE RUN ======'
if (Test-Path 'scenes\main_3d.tscn') {
	$smokeOut = Invoke-Godot @('--headless', 'res://scenes/main_3d.tscn', '--quit-after', '300')
	if ($smokeOut -match 'SCRIPT ERROR') {
		Write-Host 'SMOKE: FAIL' -ForegroundColor Red
	} else {
		Write-Host 'SMOKE: OK' -ForegroundColor Green
	}
}

Write-Host '====== GIT ======'
$git = Get-Command 'git' -ErrorAction SilentlyContinue
if ($git) {
	& git -C $root add -A
	$code = & git -C $root commit -m 'final: GDD-complete build'
	if ($code -eq 0) {
		$hash = (& git -C $root rev-parse HEAD) 2>$null
		Write-Host ('HASH    ' + $hash)
		& git -C $root push
	}
}

Write-Host ''
Write-Host '================== FINAL SUMMARY ==================' -ForegroundColor Cyan
Write-Host 'Music wavs   : ' (Get-ChildItem 'audio\music\*.wav' -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host 'District .tscn: ' (Get-ChildItem 'scenes\districts\*.tscn' -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host 'Compile      : ' $script:CompileStatus
Write-Host '===================================================='
Write-Host ''
Write-Host 'DONE. Export APK:' -ForegroundColor Green
Write-Host '  godot --headless --path . --export-debug "Android" build\TLS-debug.apk'