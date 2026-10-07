#!/usr/bin/env bash
# rc16 S3: the re-read of the risky APIs of the shipped GDScript (scripts/, not scripts/tools/ and not addons/): one grep per class, counts and lines.
# tools/qa_sim/proof_run keeps the output as the evidence of docs/SECURITY_REREAD_RC16.md:
#   tools/qa_sim/proof_run sec_reread -- bash tools/sec_reread.sh
cd "$(dirname "$0")/.." || exit 2
shipped() { grep -rnE --include=*.gd "$1" scripts | grep -v '^scripts/tools/' | sed 's/\r$//'; }
section() { echo; echo "== $1"; }

section "1 process, shell and code execution: OS.execute, create_process, shell_open, kill, Expression, GDScript.new, source_code, str_to_var, bytes_to_var, JavaClassWrapper, JavaScriptBridge"
shipped 'OS\.(execute|create_process|shell_open|kill|set_environment)|Expression\.new|GDScript\.new|\.source_code|str_to_var|bytes_to_var|var_to_bytes|JavaClassWrapper|JavaScriptBridge|HTTPRequest' | sed 's/^/hit: /'
echo "hits=$(shipped 'OS\.(execute|create_process|shell_open|kill|set_environment)|Expression\.new|GDScript\.new|\.source_code|str_to_var|bytes_to_var|var_to_bytes|JavaClassWrapper|JavaScriptBridge|HTTPRequest' | wc -l | tr -d ' ')"

section "2 environment and command line in shipped code"
shipped 'OS\.get_environment|OS\.get_cmdline'

section "3 network: peers, sockets, RPC annotations"
shipped 'ENetMultiplayerPeer|PacketPeerUDP|TCPServer|StreamPeerTCP|WebSocket|WebRTC'
shipped '@rpc'

section "4 reachability of the network code: every shipped mention of the lobby, of create_server, create_client, host and join"
grep -rniE --include=*.gd --include=*.tscn --include=project.godot 'lobby' scripts scenes project.godot | grep -v -E '^scripts/tools/|^scripts/ui/lobby_menu.gd|^scenes/ui/lobby.tscn' | sed 's/\r$//'
shipped 'create_server|create_client|NetworkManager\.(create|join)|LANNetwork\.(host|join)|LANDiscovery\.(start|stop)'

section "5 paths built from values: DirAccess.remove_absolute, ResourceLoader.load and load() of a variable path"
shipped 'DirAccess\.(remove_absolute|open)'
shipped 'load\((path|p|file|f|name)\)|ResourceLoader\.load\((path|p)'

section "6 files the player can edit: FileAccess.open and JSON.parse_string"
shipped 'FileAccess\.open\(|JSON\.parse_string|JSON\.new\(\)' | grep -v '^scripts/security/attack_sim.gd'

section "7 signed state: who writes and who reads the signed envelopes"
shipped 'write_signed|_read_envelope|read_signed'
