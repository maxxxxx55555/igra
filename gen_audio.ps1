Set-Location "C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT"
$rate = 44100
$rnd = New-Object System.Random(12345)
$sfx = "assets\audio\sfx"
$mus = "assets\audio\music"
New-Item -ItemType Directory -Force -Path $sfx, $mus | Out-Null

function Save-Wav([string]$path, [float[]]$f) {
    if (Test-Path $path) { Write-Host "  skip: $path"; return }
    $n = $f.Count
    $pcm = New-Object int16[] $n
    for ($i = 0; $i -lt $n; $i++) {
        $v = $f[$i]; if ($v -gt 1) { $v = 1 }; if ($v -lt -1) { $v = -1 }
        $pcm[$i] = [int16]($v * 32767)
    }
    $bytes = New-Object byte[] ($n * 2)
    [System.Buffer]::BlockCopy($pcm, 0, $bytes, 0, $bytes.Count)
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([byte[]]@(82,73,70,70)); $bw.Write([int](36 + $bytes.Count))
    $bw.Write([byte[]]@(87,65,86,69,102,109,116,32)); $bw.Write([int]16)
    $bw.Write([int16]1); $bw.Write([int16]1); $bw.Write([int]$rate)
    $bw.Write([int]($rate * 2)); $bw.Write([int16]2); $bw.Write([int16]16)
    $bw.Write([byte[]]@(100,97,116,97)); $bw.Write([int]$bytes.Count); $bw.Write($bytes)
    [System.IO.File]::WriteAllBytes($path, $ms.ToArray())
    $bw.Close(); $ms.Close()
    Write-Host "  created: $path" -ForegroundColor Green
}
function Noise([float]$s, [float]$sm, [float]$amp, [float]$dec) {
    $n = [int]($s * $rate); $f = New-Object float[] $n; $lp = 0
    for ($i = 0; $i -lt $n; $i++) {
        $w = $rnd.NextDouble() * 2 - 1
        $lp = $lp * $sm + $w * (1 - $sm)
        $f[$i] = $lp * [math]::Pow(1 - $i / $n, $dec) * $amp
    }
    return ,$f
}
function Tone([float]$s, [float]$fr, [float]$amp, [float]$dec) {
    $n = [int]($s * $rate); $f = New-Object float[] $n
    for ($i = 0; $i -lt $n; $i++) {
        $f[$i] = [math]::Sin(2 * [math]::PI * $fr * $i / $rate) * $amp * [math]::Pow(1 - $i / $n, $dec)
    }
    return ,$f
}
function Sweep([float]$s, [float]$f0, [float]$f1, [float]$amp, [float]$dec) {
    $n = [int]($s * $rate); $f = New-Object float[] $n; $ph = 0
    for ($i = 0; $i -lt $n; $i++) {
        $ph += 2 * [math]::PI * ($f0 + ($f1 - $f0) * ($i / $n)) / $rate
        $f[$i] = [math]::Sin($ph) * $amp * [math]::Pow(1 - $i / $n, $dec)
    }
    return ,$f
}
function Mix([float[]]$a, [float[]]$b) {
    $n = [math]::Max($a.Count, $b.Count); $f = New-Object float[] $n
    for ($i = 0; $i -lt $n; $i++) {
        $v = 0; if ($i -lt $a.Count) { $v += $a[$i] }; if ($i -lt $b.Count) { $v += $b[$i] }
        $f[$i] = $v
    }
    return ,$f
}

Write-Host "SFX..." -ForegroundColor Cyan
Save-Wav "$sfx\sfx_step.wav"        (Noise 0.18 0.75 0.7 2)
Save-Wav "$sfx\step_concrete.wav"   (Noise 0.16 0.6 0.8 3)
Save-Wav "$sfx\step_dirt.wav"       (Noise 0.2 0.85 0.6 2)
Save-Wav "$sfx\step_clank.wav"      (Mix (Noise 0.2 0.6 0.5 3) (Tone 0.25 800 0.4 4))
Save-Wav "$sfx\sfx_jump.wav"        (Sweep 0.25 180 320 0.6 1)
Save-Wav "$sfx\sfx_hurt.wav"        (Sweep 0.3 250 90 0.7 1)
Save-Wav "$sfx\sfx_shoot.wav"       (Mix (Noise 0.22 0.5 0.9 3) (Tone 0.22 90 0.7 4))
Save-Wav "$sfx\sfx_flashlight_off.wav" (Noise 0.06 0.3 0.5 2)
Save-Wav "$sfx\sfx_click.wav"       (Noise 0.04 0.2 0.6 2)
$n = [int](0.5 * $rate); $f = New-Object float[] $n; $lp = 0
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate; $v = 0; $w = $rnd.NextDouble() * 2 - 1
    if ($t -lt 0.03 -or ($t -gt 0.18 -and $t -lt 0.21) -or ($t -gt 0.36 -and $t -lt 0.4)) { $v += $w * 0.7 }
    if ($t -gt 0.3 -and $t -lt 0.45) { $lp = $lp * 0.7 + $w * 0.3; $v += $lp * 0.3 }
    $f[$i] = $v
}
Save-Wav "$sfx\sfx_reload.wav" $f
$n = [int](6 * $rate); $f = New-Object float[] $n; $lp = 0
for ($i = 0; $i -lt $n; $i++) {
    $w = $rnd.NextDouble() * 2 - 1
    $lp = $lp * 0.985 + $w * 0.015
    $f[$i] = $lp * (0.5 + 0.5 * [math]::Sin(2 * [math]::PI * 0.25 * $i / $rate)) * 1.2
}
Save-Wav "$sfx\wind.wav" $f
$n = [int](4 * $rate); $f = New-Object float[] $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $fade = [math]::Min(1, [math]::Min($t, 4 - $t) / 0.05)
    $f[$i] = (0.3 * [math]::Sin(2 * [math]::PI * 100 * $t) + 0.12 * [math]::Sin(2 * [math]::PI * 200 * $t) + 0.05 * [math]::Sin(2 * [math]::PI * 300 * $t)) * $fade
}
Save-Wav "$sfx\amb_lamp_hum.wav" $f

Write-Host "Music..." -ForegroundColor Cyan
$secs = 20; $n = [int]($secs * $rate); $f = New-Object float[] $n; $lp = 0
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $w = $rnd.NextDouble() * 2 - 1
    $lp = $lp * 0.98 + $w * 0.02
    $fade = [math]::Min(1, [math]::Min($t, $secs - $t) / 0.1)
    $f[$i] = (0.25 * [math]::Sin(2 * [math]::PI * 55 * $t) + 0.15 * [math]::Sin(2 * [math]::PI * 57.3 * $t) + 0.12 * $lp) * $fade
}
Save-Wav "$mus\Ambient_Dark.wav" $f
$n = [int]($secs * $rate); $f = New-Object float[] $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $fade = [math]::Min(1, [math]::Min($t, $secs - $t) / 0.1)
    $v = 0.2 * [math]::Sin(2 * [math]::PI * 110 * $t) + 0.12 * [math]::Sin(2 * [math]::PI * 164.8 * $t)
    if ($t -gt 3 -and $t -lt 5) { $d = $t - 3; $v += 0.15 * [math]::Sin(2 * [math]::PI * 523 * $d) * [math]::Exp(-2 * $d) }
    if ($t -gt 9 -and $t -lt 11) { $d = $t - 9; $v += 0.15 * [math]::Sin(2 * [math]::PI * 659 * $d) * [math]::Exp(-2 * $d) }
    if ($t -gt 15 -and $t -lt 17) { $d = $t - 15; $v += 0.15 * [math]::Sin(2 * [math]::PI * 784 * $d) * [math]::Exp(-2 * $d) }
    $f[$i] = $v * $fade
}
Save-Wav "$mus\Ambient_Lit.wav" $f
$n = [int]($secs * $rate); $f = New-Object float[] $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $fade = [math]::Min(1, [math]::Min($t, $secs - $t) / 0.1)
    $amp = 0.3 * (0.5 + 0.5 * [math]::Sin(2 * [math]::PI * 1.1 * $t))
    $v = $amp * [math]::Sin(2 * [math]::PI * 41 * $t)
    if ($t -gt 6 -and $t -lt 7.5) { $d = $t - 6; $v += 0.1 * [math]::Sin(2 * [math]::PI * (280 - 90 * $d) * $d) }
    if ($t -gt 13 -and $t -lt 14.5) { $d = $t - 13; $v += 0.1 * [math]::Sin(2 * [math]::PI * (280 - 90 * $d) * $d) }
    $f[$i] = $v * $fade
}
Save-Wav "$mus\Threat_Low.wav" $f
$n = [int]($secs * $rate); $f = New-Object float[] $n; $lp = 0
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $w = $rnd.NextDouble() * 2 - 1
    $lp = $lp * 0.9 + $w * 0.1
    $fade = [math]::Min(1, [math]::Min($t, $secs - $t) / 0.1)
    $pulse = [math]::Pow(0.5 + 0.5 * [math]::Sin(2 * [math]::PI * 2.2 * $t), 3)
    $f[$i] = (0.35 * $pulse * [math]::Sin(2 * [math]::PI * 45 * $t) + 0.06 * [math]::Sin(2 * [math]::PI * 622 * $t) + 0.06 * [math]::Sin(2 * [math]::PI * 660 * $t) + 0.05 * $lp) * $fade
}
Save-Wav "$mus\Threat_High.wav" $f
$secs = 12; $n = [int]($secs * $rate); $f = New-Object float[] $n; $lp = 0
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $w = $rnd.NextDouble() * 2 - 1
    $lp = $lp * 0.7 + $w * 0.3
    $v = 0
    if ($t -lt 0.4) { $v += $lp * (1 - $t / 0.4) * 0.5 }
    $v += 0.5 * [math]::Sin(2 * [math]::PI * 55 * $t) * [math]::Exp(-1.5 * $t)
    $v += (0.15 * [math]::Sin(2 * [math]::PI * 55 * $t) + 0.1 * [math]::Sin(2 * [math]::PI * 58 * $t)) * [math]::Min(1, $t / 3)
    if ($t -gt 9) { $v *= 1 - ($t - 9) / 3 }
    $f[$i] = $v
}
Save-Wav "$mus\Action_Sting.wav" $f
Write-Host "ГОТОВО. Файлов создано." -ForegroundColor Cyan