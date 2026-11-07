#requires -Version 5.1
<#
.SYNOPSIS
  Convertit des fichiers audio en AAC/M4A prêts à être envoyés sur Supabase Storage.

.DESCRIPTION
  - Encode en AAC-LC (compatible Android et iOS) avec l'option +faststart pour
    permettre la lecture avant la fin du téléchargement et le seek.
  - Peut recadrer les pochettes en 600 x 600 JPEG si elles sont fournies.
  - Génère un manifest CSV et JSON avec les métadonnées à importer dans la
    table `tracks` de Supabase.
  - Ne touche jamais aux fichiers d'origine.

.PARAMETER InputDir
  Dossier contenant les fichiers à convertir. Créé s'il n'existe pas.

.PARAMETER OutputDir
  Dossier de sortie (audio/, covers/, manifest.csv, manifest.json).

.PARAMETER BitrateKbps
  Débit AAC en kbps. 128 par défaut (bon compromis), 96 pour alléger.

.PARAMETER DryRun
  Liste les conversions sans encoder.

.EXAMPLE
  .\tool\convert_audio.ps1

.EXAMPLE
  .\tool\convert_audio.ps1 -InputDir music_in -OutputDir music_out -BitrateKbps 96
#>
[CmdletBinding()]
param(
  [string]$InputDir = 'music_in',
  [string]$OutputDir = 'music_out',
  [ValidateRange(64, 320)]
  [int]$BitrateKbps = 128,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$audioExtensions = @(
  '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.oga', '.wma', '.aiff', '.aif'
)
$coverExtensions = @('.jpg', '.jpeg', '.png', '.webp')

function ConvertTo-Slug {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return 'track' }

  $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
  $builder = New-Object System.Text.StringBuilder
  foreach ($ch in $normalized.ToCharArray()) {
    $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
    if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$builder.Append($ch)
    }
  }
  $slug = $builder.ToString().Normalize([Text.NormalizationForm]::FormC).ToLowerInvariant()
  $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-').Trim('-')
  if ([string]::IsNullOrEmpty($slug)) { return 'track' }
  return $slug
}

function Format-Size {
  param([double]$Bytes)
  if ($Bytes -ge 1GB) { return ('{0:N2} Go' -f ($Bytes / 1GB)) }
  if ($Bytes -ge 1MB) { return ('{0:N1} Mo' -f ($Bytes / 1MB)) }
  return ('{0:N0} Ko' -f ($Bytes / 1KB))
}

$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobeCmd = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffmpegCmd -or -not $ffprobeCmd) {
  Write-Host 'ffmpeg/ffprobe introuvable.' -ForegroundColor Yellow
  Write-Host 'Installe-le avec :' -ForegroundColor Yellow
  Write-Host '  winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements'
  Write-Host 'Ferme puis rouvre le terminal, et relance ce script.'
  exit 1
}
$ffmpeg = $ffmpegCmd.Source
$ffprobe = $ffprobeCmd.Source

if (-not (Test-Path -LiteralPath $InputDir)) {
  New-Item -ItemType Directory -Path $InputDir | Out-Null
  Write-Host "Dossier créé : $InputDir" -ForegroundColor Green
  Write-Host 'Place tes fichiers audio dedans, puis relance le script.'
  exit 0
}

$files = @(
  Get-ChildItem -LiteralPath $InputDir -File -Recurse |
    Where-Object { $audioExtensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object FullName
)

if ($files.Count -eq 0) {
  Write-Host "Aucun fichier audio trouvé dans $InputDir." -ForegroundColor Yellow
  Write-Host ('Extensions acceptées : ' + ($audioExtensions -join ', '))
  exit 0
}

$audioOut = Join-Path $OutputDir 'audio'
$coverOut = Join-Path $OutputDir 'covers'
New-Item -ItemType Directory -Force -Path $audioOut | Out-Null
New-Item -ItemType Directory -Force -Path $coverOut | Out-Null

Write-Host ''
Write-Host "Conversion de $($files.Count) fichier(s) en AAC $BitrateKbps kbps" -ForegroundColor Cyan
Write-Host "Sortie : $OutputDir" -ForegroundColor DarkGray
Write-Host ''

$rows = New-Object System.Collections.Generic.List[object]
$usedSlugs = @{}
$errors = 0
$index = 0
$inputBytes = 0
$outputBytes = 0
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files) {
  $index++
  $percent = [int](($index - 1) / $files.Count * 100)
  Write-Progress -Activity 'Conversion audio' `
    -Status "$index/$($files.Count) - $($file.Name)" `
    -PercentComplete $percent

  $base = [IO.Path]::GetFileNameWithoutExtension($file.Name)
  $slug = ConvertTo-Slug $base
  $suffix = 2
  while ($usedSlugs.ContainsKey($slug)) {
    $slug = '{0}-{1}' -f (ConvertTo-Slug $base), $suffix
    $suffix++
  }
  $usedSlugs[$slug] = $true

  $outFile = Join-Path $audioOut "$slug.m4a"
  $inputBytes += $file.Length

  if ($DryRun) {
    Write-Host "[dry-run] $($file.Name)  ->  audio/$slug.m4a" -ForegroundColor DarkGray
    continue
  }

  $duration = 0.0
  $title = $base
  $artist = ''
  try {
    $probeJson = & $ffprobe -v error -show_entries 'format=duration:format_tags=title,artist' -of json $file.FullName 2>$null | Out-String
    $info = $probeJson | ConvertFrom-Json
    if ($null -ne $info.format.duration) { $duration = [double]$info.format.duration }
    if ($null -ne $info.format.tags.title -and $info.format.tags.title) { $title = [string]$info.format.tags.title }
    if ($null -ne $info.format.tags.artist -and $info.format.tags.artist) { $artist = [string]$info.format.tags.artist }
  } catch {
    Write-Host "  Métadonnées illisibles, valeurs par défaut utilisées." -ForegroundColor DarkYellow
  }

  & $ffmpeg -hide_banner -loglevel error -y -i $file.FullName `
    -vn -map_metadata -1 `
    -metadata "title=$title" -metadata "artist=$artist" `
    -c:a aac -b:a "$($BitrateKbps)k" -ar 44100 -ac 2 `
    -movflags +faststart $outFile

  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outFile)) {
    Write-Host "  Échec : $($file.Name)" -ForegroundColor Red
    $errors++
    continue
  }

  $outSize = (Get-Item -LiteralPath $outFile).Length
  $outputBytes += $outSize

  $coverPath = ''
  $coverSource = $null
  foreach ($ext in $coverExtensions) {
    $candidate = Join-Path $file.DirectoryName "$base$ext"
    if (Test-Path -LiteralPath $candidate) { $coverSource = $candidate; break }
  }
  if (-not $coverSource) {
    foreach ($ext in $coverExtensions) {
      $candidate = Join-Path (Join-Path $InputDir 'covers') "$slug$ext"
      if (Test-Path -LiteralPath $candidate) { $coverSource = $candidate; break }
    }
  }

  if ($coverSource) {
    $coverFile = Join-Path $coverOut "$slug.jpg"
    & $ffmpeg -hide_banner -loglevel error -y -i $coverSource `
      -vf 'scale=600:600:force_original_aspect_ratio=increase,crop=600:600' `
      -q:v 3 $coverFile
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $coverFile)) {
      $coverPath = "covers/$slug.jpg"
    }
  }

  $rows.Add([pscustomobject]@{
    id               = $slug
    title            = $title
    artist           = $artist
    duration_seconds = [int][math]::Round($duration)
    audio_path       = "audio/$slug.m4a"
    cover_path       = $coverPath
    size_kb          = [int][math]::Round($outSize / 1KB)
    source_file      = $file.Name
  })

  $saved = if ($file.Length -gt 0) { (1 - ($outSize / $file.Length)) * 100 } else { 0 }
  Write-Host ("  {0} -> {1}  ({2} -> {3}, {4:N0} % de gagné)" -f `
      $file.Name, "$slug.m4a", (Format-Size $file.Length), (Format-Size $outSize), $saved) `
    -ForegroundColor Green
}

Write-Progress -Activity 'Conversion audio' -Completed
$stopwatch.Stop()

if ($DryRun) {
  Write-Host ''
  Write-Host 'Mode dry-run : aucun fichier encodé.' -ForegroundColor Yellow
  exit 0
}

$csvPath = Join-Path $OutputDir 'manifest.csv'
$jsonPath = Join-Path $OutputDir 'manifest.json'
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$json = $rows | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText(
  (Join-Path (Get-Location) $jsonPath),
  $json,
  (New-Object System.Text.UTF8Encoding($false))
)

Write-Host ''
Write-Host 'Terminé.' -ForegroundColor Cyan
Write-Host ("  Fichiers convertis : {0}" -f $rows.Count)
if ($errors -gt 0) {
  Write-Host ("  Échecs : {0}" -f $errors) -ForegroundColor Red
}
Write-Host ("  Entrée : {0}" -f (Format-Size $inputBytes))
Write-Host ("  Sortie : {0}" -f (Format-Size $outputBytes))
if ($inputBytes -gt 0) {
  Write-Host ("  Gain   : {0:N0} %" -f ((1 - ($outputBytes / $inputBytes)) * 100))
}
Write-Host ("  Durée  : {0:N1} s" -f $stopwatch.Elapsed.TotalSeconds)
Write-Host ("  Manifest CSV : {0}" -f $csvPath)
Write-Host ("  Manifest JSON: {0}" -f $jsonPath)
