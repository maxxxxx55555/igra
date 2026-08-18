# Заблокировано

## CrazyGames/SDK-Godot не клонируется

```
git clone --depth 1 https://github.com/CrazyGames/SDK-Godot.git
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/CrazyGames/SDK-Godot.git/'
```

GitHub отвечает запросом аутентификации на анонимный клон — так он отвечает и для
приватных, и для удалённых репозиториев. Публично репозиторий по этому адресу
недоступен.

**Что это значит.** Веб-провайдер рекламы (CrazyGames) реализовать не по чему.
На мобильную рекламу это не влияет: `Poing-Studios/godot-admob` и
`AppLovin/AppLovin-MAX-Godot` склонированы в `..\refs\` и доступны офлайн.

**Что делать человеку, если веб-таргет нужен.** Проверить актуальный адрес SDK на
crazygames.com/developer, либо склонировать под своей учётной записью:
`gh repo clone CrazyGames/SDK-Godot ../refs/SDK-Godot`. Абстракция `AdService`
пишется провайдер-независимой, так что веб-провайдер добавляется отдельным файлом
без правок игрового кода.
