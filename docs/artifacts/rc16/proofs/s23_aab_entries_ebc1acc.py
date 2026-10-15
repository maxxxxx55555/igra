# The entries of the bundle that CORRECTION_LOG 242, 243 and 245 are about: the two scripts under scripts/security, the 15 skill icons (the pack holds each as <name>.png.import and an imported .astc.ctex, not as a .png), the two UI stings (the .ogg.import and the imported .oggvorbisstr) and the integrity guard.
# usage: python aab_entries.py build/tls.aab
import sys
import zipfile

names = [i.filename for i in zipfile.ZipFile(sys.argv[1]).infolist()]
sec = [x for x in names if "scripts/security" in x]
icon_imports = [x for x in names if "icons/skills/" in x and x.endswith(".png.import")]
stings = [x for x in names if "ui_ending_sting" in x or "ui_streak_milestone_sting" in x]
guard = [x for x in names if "integrity_guard" in x]
attack = [x for x in names if "attack_sim" in x]
print(len(names), "entries")
print("entries under scripts/security:", len(sec))
[print(" ", x) for x in sec]
print("entries naming attack_sim:", len(attack))
print("skill icons as .png.import under icons/skills:", len(icon_imports))
print("ui sting entries:", len(stings))
[print(" ", x) for x in stings]
print("integrity_guard entries:", len(guard))
[print(" ", x) for x in guard]
