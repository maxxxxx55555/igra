#!/usr/bin/env python3
# Добавляет ключи enc_title/enc_locked во все data/i18n/*.json, если их ещё нет.
import json, os

EXTRA = {
    "en":    ("Creature Encyclopedia", "Encounter the creature to unlock the entry."),
    "ru":    ("Энциклопедия существ",  "Встретьте существо, чтобы открыть запись."),
    "de":    ("Kreaturen-Enzyklopädie", "Begegne der Kreatur, um den Eintrag freizuschalten."),
    "fr":    ("Encyclopédie des créatures", "Rencontrez la créature pour débloquer l'entrée."),
    "es":    ("Enciclopedia de criaturas", "Encuentra la criatura para desbloquear la entrada."),
    "it":    ("Enciclopedia delle creature", "Incontra la creatura per sbloccare la voce."),
    "pt_BR": ("Enciclopédia de criaturas", "Encontre a criatura para desbloquear a entrada."),
    "ja":    ("クリーチャー図鑑", "クリーチャーに遭遇すると記録が解放されます。"),
    "ko":    ("괴물 백과사전", "괴물을 만나면 항목이 해금됩니다."),
    "zh":    ("生物图鉴", "遇到生物以解锁条目。"),
    "zh_TW": ("生物圖鑑", "遇到生物以解鎖條目。"),
    "tr":    ("Yaratık Ansiklopedisi", "Kaydı açmak için yaratıkla karşılaşın."),
    "ar":    ("موسوعة المخلوقات", "قابل المخلوق لفتح الإدخال."),
}

added = {}
for fn in os.listdir("data/i18n"):
    if not fn.endswith(".json"):
        continue
    lang = fn[:-5]
    path = os.path.join("data/i18n", fn)
    with open(path, "r", encoding="utf-8") as f:
        d = json.load(f)
    t = EXTRA.get(lang, EXTRA["en"])
    new = 0
    if "enc_title" not in d:
        d["enc_title"] = t[0]; new += 1
    if "enc_locked" not in d:
        d["enc_locked"] = t[1]; new += 1
    if new:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
        added[path] = new
print(added)
