$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$releaseExe = Join-Path $root "src-tauri\target\release\batchlapse.exe"
$portableDir = Join-Path $root "dist-portable"
$portableBin = Join-Path $portableDir "bin"

if (-not (Test-Path -LiteralPath $releaseExe)) {
  throw "Release executable not found. Run 'npm run tauri:build' first."
}

New-Item -ItemType Directory -Force -Path $portableDir, $portableBin | Out-Null
Copy-Item -Force -LiteralPath $releaseExe -Destination (Join-Path $portableDir "BatchLapse.exe")
Copy-Item -Force -LiteralPath (Join-Path $root "README.md") -Destination (Join-Path $portableDir "README.md")

$ffmpeg = Join-Path $root "bin\ffmpeg.exe"
$ffprobe = Join-Path $root "bin\ffprobe.exe"
if (-not ((Test-Path -LiteralPath $ffmpeg) -and (Test-Path -LiteralPath $ffprobe))) {
  $defaultFfmpegDir = "D:\Tools\ffmpeg\bin"
  $defaultFfmpeg = Join-Path $defaultFfmpegDir "ffmpeg.exe"
  $defaultFfprobe = Join-Path $defaultFfmpegDir "ffprobe.exe"
  if ((Test-Path -LiteralPath $defaultFfmpeg) -and (Test-Path -LiteralPath $defaultFfprobe)) {
    $ffmpeg = $defaultFfmpeg
    $ffprobe = $defaultFfprobe
  }
}
if ((Test-Path -LiteralPath $ffmpeg) -and (Test-Path -LiteralPath $ffprobe)) {
  Copy-Item -Force -LiteralPath $ffmpeg -Destination (Join-Path $portableBin "ffmpeg.exe")
  Copy-Item -Force -LiteralPath $ffprobe -Destination (Join-Path $portableBin "ffprobe.exe")
}

Write-Host "Portable folder created at $portableDir"
