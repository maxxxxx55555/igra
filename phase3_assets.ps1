Set-Location "C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT"
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path "assets\textures\environment", "assets\art", "assets\ui" | Out-Null
$rnd = New-Object System.Random(7)
$w = 256
$h = 256

# ---------- 1. ТЕКСТУРЫ ----------
$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $g = 40 + $rnd.Next(-12, 13)
    if ($x -ge 120 -and $x -le 136 -and ($y % 64) -lt 40) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(200, 180, 60))
    } else {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($g, $g, $g + 3))
    }
  }
}
$bmp.Save("assets\textures\environment\asphalt.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $g = 95 + $rnd.Next(-10, 11)
    if ((($x * 7 + $y * 13) % 97) -lt 2) { $g = $g - 45 }
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($g, $g, $g))
  }
}
$bmp.Save("assets\textures\environment\concrete.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $row = [math]::Floor($y / 32)
    $off = 0
    if ($row % 2 -eq 1) { $off = 32 }
    $bx = ($x + $off) % 64
    if ($bx -lt 3 -or ($y % 32) -lt 3) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(60, 58, 55))
    } else {
      $n = $rnd.Next(-12, 13)
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(120 + $n, 62 + $n, 50 + $n))
    }
  }
}
$bmp.Save("assets\textures\environment\brick.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $n = $rnd.Next(-18, 19)
    if ($rnd.NextDouble() -gt 0.92) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(120 + $n, 70 + $n, 35))
    } else {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(75 + $n, 72 + $n, 70 + $n))
    }
  }
}
$bmp.Save("assets\textures\environment\rusty_metal.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $n = $rnd.Next(-14, 15)
    if ($rnd.NextDouble() -gt 0.985) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(140, 130, 110))
    } else {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(85 + $n, 65 + $n, 45 + $n))
    }
  }
}
$bmp.Save("assets\textures\environment\dirt.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Текстуры готовы (5)" -ForegroundColor Green

# ---------- 2. АРТ ----------
$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $g = 45 + $rnd.Next(-10, 11)
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($g, $g, $g + 2))
  }
}
$bmp.Save("assets\art\tile_floor.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap($w, $h)
for ($x = 0; $x -lt $w; $x++) {
  for ($y = 0; $y -lt $h; $y++) {
    $row = [math]::Floor($y / 32)
    $off = 0
    if ($row % 2 -eq 1) { $off = 32 }
    if ((($x + $off) % 64) -lt 3 -or ($y % 32) -lt 3) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(55, 52, 50))
    } else {
      $n = $rnd.Next(-10, 11)
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(105 + $n, 58 + $n, 48 + $n))
    }
  }
}
$bmp.Save("assets\art\tile_wall.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap(64, 64)
for ($x = 0; $x -lt 64; $x++) {
  for ($y = 0; $y -lt 64; $y++) {
    $dx = $x - 32
    $dy = $y - 32
    $d = [math]::Sqrt($dx * $dx + $dy * $dy)
    if ($d -le 9) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 200, 170, 130))
    } elseif ($d -le 18) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 40, 50, 70))
    }
  }
}
for ($x = 26; $x -lt 38; $x++) {
  for ($y = 4; $y -lt 14; $y++) {
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(200, 255, 213, 74))
  }
}
$bmp.Save("assets\art\player_top.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$bmp = New-Object System.Drawing.Bitmap(32, 32)
for ($x = 0; $x -lt 32; $x++) {
  for ($y = 0; $y -lt 32; $y++) {
    $dx = $x - 16
    $dy = $y - 16
    $d = [math]::Sqrt($dx * $dx + $dy * $dy)
    if ($d -le 10) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 255, 213, 74))
    } elseif ($d -le 12) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 180, 140, 20))
    }
  }
}
$bmp.Save("assets\art\coin_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$W = 960
$H = 540
$bmp = New-Object System.Drawing.Bitmap($W, $H)
for ($x = 0; $x -lt $W; $x++) {
  for ($y = 0; $y -lt $H; $y++) {
    $t = $y / $H
    $cr = [int](8 + 8 * $t)
    $cg = [int](12 + 10 * $t)
    $cb = [int](30 - 12 * $t)
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($cr, $cg, $cb))
  }
}
$bx0 = 0
while ($bx0 -lt $W) {
  $bw2 = $rnd.Next(60, 140)
  $bh2 = $rnd.Next(150, 420)
  $top = $H - $bh2
  $xend = $bx0 + $bw2
  if ($xend -gt $W) { $xend = $W }
  for ($bx = $bx0; $bx -lt $xend; $bx++) {
    for ($by = $top; $by -lt $H; $by++) {
      $bmp.SetPixel($bx, $by, [System.Drawing.Color]::FromArgb(8, 10, 14))
    }
  }
  for ($wx = $bx0 + 8; $wx -lt $xend - 8; $wx += 16) {
    for ($wy = $top + 10; $wy -lt $H - 10; $wy += 22) {
      if ($rnd.NextDouble() -gt 0.85) {
        for ($i = 0; $i -lt 4; $i++) {
          for ($j = 0; $j -lt 6; $j++) {
            $px = $wx + $i
            $py = $wy + $j
            if ($px -lt $W -and $py -lt $H) {
              $bmp.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(255, 213, 74))
            }
          }
        }
      }
    }
  }
  $bx0 = $bx0 + $bw2 + $rnd.Next(6, 20)
}
$bmp.Save("assets\art\menu_bg.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Арт готов (5)" -ForegroundColor Green

# ---------- 3. ИКОНКИ SVG ----------
@'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect x="24" y="8" width="16" height="48" fill="#c41e1e"/><rect x="8" y="24" width="48" height="16" fill="#c41e1e"/></svg>
'@ | Set-Content "assets\ui\ui_health.svg" -Encoding utf8
@'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect x="26" y="24" width="12" height="28" fill="#b8860b"/><path d="M26 24 L32 8 L38 24 Z" fill="#ffd54a"/></svg>
'@ | Set-Content "assets\ui\ui_ammo.svg" -Encoding utf8
@'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><circle cx="32" cy="42" r="10" fill="#ffffff"/><path d="M24 36 L14 10 L50 10 L40 36 Z" fill="#ffd54a" opacity="0.7"/></svg>
'@ | Set-Content "assets\ui\ui_flashlight.svg" -Encoding utf8
@'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect x="12" y="20" width="34" height="28" fill="#2e7d32"/><rect x="46" y="28" width="6" height="12" fill="#2e7d32"/><rect x="16" y="24" width="8" height="20" fill="#66bb6a"/></svg>
'@ | Set-Content "assets\ui\ui_battery.svg" -Encoding utf8
@'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><circle cx="32" cy="32" r="24" fill="none" stroke="#ffffff" stroke-width="4"/><text x="32" y="42" font-size="28" text-anchor="middle" fill="#ffffff" font-family="Arial">E</text></svg>
'@ | Set-Content "assets\ui\ui_interact.svg" -Encoding utf8
Write-Host "Иконки готовы (5)" -ForegroundColor Green
Write-Host "ФАЗА 3: ВСЕ АССЕТЫ СОЗДАНЫ" -ForegroundColor Cyan