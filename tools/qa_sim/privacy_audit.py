# -*- coding: utf-8 -*-
"""Privacy audit gate (Session 23): every place the game could talk to the network, an analytics service or an ad SDK is found by grep and must be listed in ROWS
with a status (ACTIVE, PLAYER-INITIATED, INACTIVE, STUB, BUILD-TIME) and the reason. A hit in a file that no row names, or a row whose file has no hit, fails.

usage: python tools/qa_sim/privacy_audit.py [--check] [--write docs/PRIVACY_AUDIT.md] [--demo]
"""
import collections
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCAN = ["scripts", "scenes", "addons", "project.godot", "export_presets.cfg", "android/build/build.gradle", "android/build/AndroidManifest.xml"]
SKIP = ("scripts/tools/", "scenes/tools/", "android/build/build/")
SUFFIXES = {".gd", ".tscn", ".cfg", ".godot", ".xml", ".gradle", ".gdextension", ".java", ".kt"}
PATTERNS = {
    "http": r"HTTPRequest|HTTPClient",
    "socket": r"WebSocketPeer|PacketPeerUDP|StreamPeerTCP|TCPServer|UDPServer|StreamPeerTLS",
    "enet": r"ENetMultiplayerPeer|WebRTCPeer|WebRTCMultiplayerPeer",
    "upnp": r"UPNP",
    "url": r"https?://",
    "analytics": r"[Ff]irebase|[Cc]rashlytics|[Aa]nalytics|Sentry|AppsFlyer",
    "ads": r"AppLovin|applovin|AdService|AdMob|admob",
    "integrity": r"play_integrity|PlayIntegrity",
    "platform": r"OS\.shell_open|OS\.execute|JavaClassWrapper",
}
# (kind, file, status, reason)
ROWS = [
    ("enet", "scripts/multiplayer/network_manager.gd", "INACTIVE", "create_server() and join_server() are called by scripts/ui/lobby_menu.gd only, and no screen opens the lobby (see LOBBY_FILES); no peer is ever made"),
    ("enet", "scripts/net/lan_network.gd", "INACTIVE", "the LAN prototype's peer; no file but the lobby reaches it (docs/A10_multiplayer_decision.md)"),
    ("upnp", "scripts/multiplayer/network_manager.gd", "INACTIVE", "enable_upnp is false by default and the code that would use it is the unreachable lobby's"),
    ("socket", "scripts/multiplayer/lan_discovery.gd", "INACTIVE", "UDP on the local network to list games, started by the unreachable lobby only"),
    ("ads", "addons/applovin_max/AppLovinMAX.gd", "INACTIVE", "the plugin is not in the export: export_presets.cfg has gradle_build/plugins_enabled empty"),
    ("ads", "addons/applovin_max/AppLovinMAXDictionaryUtils.gd", "INACTIVE", "same plugin, not in the export"),
    ("ads", "scripts/monetization/ad_service.gd", "STUB", "_default_provider returns no provider in a release build without monetization/applovin_sdk_key, so every reward offer hides itself; debug builds get the claim-button stub"),
    ("ads", "scripts/monetization/applovin_provider.gd", "INACTIVE", "made only on a mobile build with a non-empty SDK key; the key is empty in project.godot"),
    ("ads", "scripts/core/game_manager.gd", "STUB", "listens to AdService.reward_granted; nothing is granted while no provider exists"),
    ("ads", "scripts/death_screen.gd", "STUB", "offers a revive only when AdService.can_show_reward is true (never without a provider)"),
    ("ads", "scripts/ui/hud_3d.gd", "STUB", "offers the extra battery only when AdService.can_show_reward is true (never without a provider)"),
    ("ads", "scripts/security/attack_sim.gd", "STUB", "the attack simulation drives both branches of _default_provider"),
    ("ads", "scripts/systems/music_manager.gd", "STUB", "a comment: an interstitial waits while a fight plays"),
    ("ads", "scripts/systems/play_integrity_service.gd", "STUB", "a comment: the integrity service has the same shape as AdService and no real provider"),
    ("ads", "project.godot", "STUB", "the AdService autoload and the empty monetization/applovin_* settings"),
    ("integrity", "project.godot", "STUB", "the PlayIntegrityService autoload; no Play Integrity API call exists without a provider"),
    ("platform", "scripts/systems/integrity_guard.gd", "ACTIVE", "JavaClassWrapper reads android.os.Debug.isDebuggerConnected() on the device: a local check, nothing leaves the device"),
    ("url", "android/build/build.gradle", "BUILD-TIME", "the repositories the Gradle build downloads its libraries from; not part of the running game"),
]


def hits():
    found = collections.defaultdict(collections.Counter)
    for entry in SCAN:
        path = ROOT / entry
        files = [path] if path.is_file() else [f for f in path.rglob("*") if f.is_file() and f.suffix in SUFFIXES]
        for f in files:
            rel = f.relative_to(ROOT).as_posix()
            if rel.startswith(SKIP) or "/.godot/" in rel:
                continue
            text = f.read_text(encoding="utf-8", errors="replace")
            for kind, rx in PATTERNS.items():
                n = len(re.findall(rx, text))
                if n:
                    found[kind][rel] += n
    return found


# The only files that name the lobby: its scene and its script. A third file would be a way into it.
LOBBY_FILES = {"scenes/ui/lobby.tscn", "scripts/ui/lobby_menu.gd"}


def lobby_references():
    out = set()
    for entry in ("scripts", "scenes", "project.godot"):
        path = ROOT / entry
        for f in [path] if path.is_file() else path.rglob("*"):
            rel = f.relative_to(ROOT).as_posix()
            if f.is_file() and f.suffix in (".gd", ".tscn", ".godot") and not rel.startswith(SKIP):
                if re.search(r"lobby", f.read_text(encoding="utf-8", errors="replace"), re.I):
                    out.add(rel)
    return out - LOBBY_FILES


def findings(found, lobby=None):
    listed = {(kind, file) for kind, file, _, _ in ROWS}
    out = ["The lobby is named by %s: an INACTIVE multiplayer row is no longer true" % f for f in sorted(lobby_references() if lobby is None else lobby)]
    for kind, counter in found.items():
        for rel in counter:
            if (kind, rel) not in listed:
                out.append("UNLISTED %s hit in %s: classify it in tools/qa_sim/privacy_audit.py ROWS" % (kind, rel))
    for kind, file, _, _ in ROWS:
        if file == "android/build/build.gradle" and not (ROOT / file).is_file():
            continue
        if file not in found.get(kind, {}):
            out.append("STALE row: no %s hit in %s any more" % (kind, file))
    return out


def permissions():
    text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8", errors="replace")
    return sorted(set(re.findall(r"^permissions/(\w+)=true", text, re.M)))


def table(found):
    lines = ["| Kind | File | Hits | Status | Why |", "|---|---|---|---|---|"]
    for kind, file, status, reason in ROWS:
        lines.append("| %s | `%s` | %d | %s | %s |" % (kind, file, found.get(kind, {}).get(file, 0), status, reason))
    return "\n".join(lines)


def write(path, found):
    perms = permissions()
    body = [
        "# Privacy audit (Session 23)",
        "",
        "Generated by `python tools/qa_sim/privacy_audit.py --write docs/PRIVACY_AUDIT.md`; `--check` is a static gate of `tools/check.sh`: a network, analytics or ad hit in a file",
        "that no row names fails it, and so does a row whose file no longer has a hit. Searched: " + ", ".join("`%s`" % s for s in SCAN) + " (not `scripts/tools/`, not `scenes/tools/`).",
        "",
        "Patterns: " + "; ".join("%s = `%s`" % (k, v) for k, v in PATTERNS.items()) + ".",
        "",
        table(found),
        "",
        "Absent (zero hits in the searched paths): HTTPRequest, HTTPClient, WebSocketPeer, TCP clients, Firebase, Crashlytics, any analytics SDK, any URL in a script or scene.",
        "",
        "Android permissions the export asks for (`export_presets.cfg`): " + ", ".join("`%s`" % p for p in perms) + ". INTERNET is there for the LAN game and the ad provider of a later build; the vibration is the haptics of the touch controls.",
        "",
        "Status words: ACTIVE runs in every session and stays on the device; INACTIVE is code that no screen or build reaches; STUB is a path that has no provider and does nothing;",
        "BUILD-TIME is not in the running game. The lobby (`scenes/ui/lobby.tscn`, `scripts/ui/lobby_menu.gd`) is named by no other file of `scripts/`, `scenes/` or `project.godot`.",
    ]
    pathlib.Path(path).write_text("\n".join(body) + "\n", encoding="utf-8")


def main(argv):
    if "--demo" in argv:
        bad = findings({"http": collections.Counter({"scripts/x.gd": 1})}, {"scripts/ui/main_menu.gd"})
        assert any(s.startswith("UNLISTED http") for s in bad) and any(s.startswith("STALE") for s in bad) and any("lobby" in s for s in bad)
        print("privacy_audit demo: an unlisted hit, a stale row and a way into the lobby are all found")
        return 0
    found = hits()
    problems = findings(found)
    for p in problems:
        print("FAIL", p)
    if "--write" in argv:
        write(argv[argv.index("--write") + 1], found)
    print("privacy_audit: %d hit file(s) in %d row(s), %d finding(s)" % (sum(len(c) for c in found.values()), len(ROWS), len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
