$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$iconDir = Join-Path $root "src-tauri\icons"
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null

function New-IconBitmap {
  param([int]$Size)

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $scale = $Size / 512.0
  function S([float]$value) { return [float]($value * $scale) }

  $bg = [System.Drawing.ColorTranslator]::FromHtml("#111418")
  $border = [System.Drawing.ColorTranslator]::FromHtml("#3d4b55")
  $amber = [System.Drawing.ColorTranslator]::FromHtml("#f4a64a")
  $amberStrong = [System.Drawing.ColorTranslator]::FromHtml("#ffb45c")
  $teal = [System.Drawing.ColorTranslator]::FromHtml("#34c4c6")

  $rect = New-Object System.Drawing.RectangleF (S 36), (S 36), (S 440), (S 440)
  $radius = S 84
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($rect.X, $rect.Y, $radius, $radius, 180, 90)
  $path.AddArc(($rect.Right - $radius), $rect.Y, $radius, $radius, 270, 90)
  $path.AddArc(($rect.Right - $radius), ($rect.Bottom - $radius), $radius, $radius, 0, 90)
  $path.AddArc($rect.X, ($rect.Bottom - $radius), $radius, $radius, 90, 90)
  $path.CloseFigure()

  $g.FillPath((New-Object System.Drawing.SolidBrush $bg), $path)
  $g.DrawPath((New-Object System.Drawing.Pen $border, (S 10)), $path)

  $arcRect = New-Object System.Drawing.RectangleF (S 118), (S 140), (S 276), (S 276)
  $g.DrawArc((New-Object System.Drawing.Pen $amber, (S 28)), $arcRect, 205, 130)

  foreach ($angle in @(215, 245, 275, 305, 335)) {
    $r1 = S 126
    $r2 = S 146
    $cx = S 256
    $cy = S 282
    $rad = ($angle * [Math]::PI) / 180.0
    $x1 = $cx + [Math]::Cos($rad) * $r1
    $y1 = $cy + [Math]::Sin($rad) * $r1
    $x2 = $cx + [Math]::Cos($rad) * $r2
    $y2 = $cy + [Math]::Sin($rad) * $r2
    $g.DrawLine((New-Object System.Drawing.Pen $amberStrong, (S 10)), [float]$x1, [float]$y1, [float]$x2, [float]$y2)
  }

  $needleAngle = 318
  $needleRad = ($needleAngle * [Math]::PI) / 180.0
  $centerX = S 256
  $centerY = S 300
  $needleLength = S 122
  $tipX = $centerX + [Math]::Cos($needleRad) * $needleLength
  $tipY = $centerY + [Math]::Sin($needleRad) * $needleLength
  $g.DrawLine((New-Object System.Drawing.Pen $teal, (S 18)), $centerX, $centerY, [float]$tipX, [float]$tipY)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush $amberStrong), (S 228), (S 272), (S 56), (S 56))
  $g.FillEllipse((New-Object System.Drawing.SolidBrush $bg), (S 244), (S 288), (S 24), (S 24))

  $g.Dispose()
  return $bmp
}

function Save-Png {
  param([int]$Size, [string]$Path)
  $bmp = New-IconBitmap -Size $Size
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

Save-Png 32 (Join-Path $iconDir "32x32.png")
Save-Png 64 (Join-Path $iconDir "64x64.png")
Save-Png 128 (Join-Path $iconDir "128x128.png")
Save-Png 256 (Join-Path $iconDir "128x128@2x.png")
Save-Png 512 (Join-Path $iconDir "icon.png")

$logoSizes = @{
  "Square30x30Logo.png" = 30
  "Square44x44Logo.png" = 44
  "Square71x71Logo.png" = 71
  "Square89x89Logo.png" = 89
  "Square107x107Logo.png" = 107
  "Square142x142Logo.png" = 142
  "Square150x150Logo.png" = 150
  "Square284x284Logo.png" = 284
  "Square310x310Logo.png" = 310
  "StoreLogo.png" = 50
}

foreach ($entry in $logoSizes.GetEnumerator()) {
  Save-Png $entry.Value (Join-Path $iconDir $entry.Key)
}

$icoSizes = @(16, 24, 32, 48, 64, 128, 256)
$entries = @()
foreach ($size in $icoSizes) {
  $stream = New-Object System.IO.MemoryStream
  $bmp = New-IconBitmap -Size $size
  $bmp.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  $entries += [pscustomobject]@{ Size = $size; Bytes = $stream.ToArray() }
  $stream.Dispose()
}

$icoPath = Join-Path $iconDir "icon.ico"
$fs = [System.IO.File]::Create($icoPath)
$writer = New-Object System.IO.BinaryWriter $fs
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]$entries.Count)
$offset = 6 + (16 * $entries.Count)
foreach ($entry in $entries) {
  $writer.Write([byte]($(if ($entry.Size -eq 256) { 0 } else { $entry.Size })))
  $writer.Write([byte]($(if ($entry.Size -eq 256) { 0 } else { $entry.Size })))
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]32)
  $writer.Write([UInt32]$entry.Bytes.Length)
  $writer.Write([UInt32]$offset)
  $offset += $entry.Bytes.Length
}
foreach ($entry in $entries) {
  $writer.Write($entry.Bytes)
}
$writer.Dispose()
$fs.Dispose()

Write-Host "Generated BatchLapse icon assets in $iconDir"
