# Генерирует debug-keystore для подписи Android-сборки TLS.
# Запуск: powershell -ExecutionPolicy Bypass -File tools/make_keystore.ps1
# Результат: project_root\tls_debug.keystore (в .gitignore — не коммитить).
# После генерации укажи путь в Editor: Export > Android > Keystore > Debug.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dname = "CN=TLS Android Debug,O=TLSCorp,C=RU"
$out = Join-Path $root "tls_debug.keystore"
$pass = "tlsdebug"

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host "keytool не найден. Установи JDK (Eclipse Adoptium 17+) или Android Studio JBR."
    exit 1
}

if (Test-Path $out) {
    Write-Host "Уже есть: $out"
    exit 0
}

& $keytool.Source -genkey -v -keystore $out -alias tlsdebug -keyalg RSA -keysize 2048 -validity 10000 -storepass $pass -keypass $pass -dname $dname | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK: $out"
Write-Host "alias: tlsdebug | storepass/keypass: $pass"
Write-Host "В Export > Android > Keystore: Debug Keystore = $out, Debug User = tlsdebug, Debug Password = $pass"