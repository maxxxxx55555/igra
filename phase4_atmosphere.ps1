Set-Location "C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT"
$f = "scenes\environment\world_env.tscn"
$t = [System.IO.File]::ReadAllText($f)
if ($t -match "fog_enabled") {
    Write-Host "Туман уже настроен" -ForegroundColor Yellow
} else {
    $lines = $t -split "`n"
    $out = @()
    $ins = $false
    foreach ($line in $lines) {
        $out += $line
        if (-not $ins -and $line -match '^\[sub_resource type="Environment"') {
            $out += "fog_enabled = true"
            $out += "fog_density = 0.02"
            $out += "fog_color = Color(0.04, 0.06, 0.1, 1)"
            $out += "glow_enabled = true"
            $out += "glow_intensity = 0.4"
            $out += "tonemap_mode = 2"
            $ins = $true
        }
    }
    if ($ins) {
        [System.IO.File]::WriteAllText($f, ($out -join "`n"))
        Write-Host "Атмосфера подключена" -ForegroundColor Green
    } else {
        Write-Host "Environment не найден - пропуск" -ForegroundColor Yellow
    }
}