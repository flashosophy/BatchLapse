param(
  [string]$Destination = (Join-Path $PSScriptRoot "..\bin")
)

$ErrorActionPreference = "Stop"
$zipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("batchlapse-ffmpeg-" + [System.Guid]::NewGuid())
$zipPath = Join-Path $tempRoot "ffmpeg.zip"

New-Item -ItemType Directory -Force -Path $tempRoot, $Destination | Out-Null

try {
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
  Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

  $ffmpeg = Get-ChildItem -Path $tempRoot -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
  $ffprobe = Get-ChildItem -Path $tempRoot -Recurse -Filter "ffprobe.exe" | Select-Object -First 1

  if (-not $ffmpeg -or -not $ffprobe) {
    throw "Downloaded archive did not contain ffmpeg.exe and ffprobe.exe."
  }

  Copy-Item -Force -LiteralPath $ffmpeg.FullName -Destination (Join-Path $Destination "ffmpeg.exe")
  Copy-Item -Force -LiteralPath $ffprobe.FullName -Destination (Join-Path $Destination "ffprobe.exe")
  Write-Host "Installed ffmpeg.exe and ffprobe.exe to $Destination"
}
finally {
  Remove-Item -Recurse -Force -LiteralPath $tempRoot -ErrorAction SilentlyContinue
}
