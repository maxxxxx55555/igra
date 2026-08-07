# Multiplayer decision (A10)
Выбор: довести LAN/код-комнату ИЛИ выпилить NetworkManager.

## Если выпиливать:
1. Удалить scenes/multiplayer/
2. Удалить scripts/network/network_manager.gd
3. Удалить scripts/network/multiplayer_player.gd
4. Убрать кнопку Multiplayer из главного меню

## Если оставлять:
- Доработать network_manager.gd: create_room() / join_room(code)
- Синхронизировать позиции игроков через MultiplayerSynchronizer
