#requires -Version 5.1
<#
.SYNOPSIS
  Convertit une bibliothèque organisée par artiste en MP3 + sous-titres JSON.

.DESCRIPTION
  Structure d'entrée attendue :

    music_in/
      Artiste A/
        Artiste A - Titre 1.mp4
        Titre 2.m4a
        sous_titre.json
        photo.jpg

  Structure de sortie :

    music_out/
      audio/artiste_titre.mp3
      lyrics/artiste_titre.json      (uniquement si un sous-titre existe)
      covers/artiste.jpg
      manifest.csv
      manifest.json

  Le nom des dossiers fournit le nom de l'artiste. Le nom du fichier audio
  fournit le titre (le préfixe artiste et les mentions « Audio Officiel »,
  « Clip Officiel », « Benin », etc. sont retirés).

  Les sous-titres au format Musixmatch (lyrics.lines[].startTimeMs / words)
  sont convertis en lignes horodatées :

      [ { "t": 2260, "text": "..." }, ... ]

  avec `t` en millisecondes. Les sous-titres non synchronisés sont répartis
  uniformément sur la durée du morceau (approximation).

  Aucun fichier d'origine n'est modifié.

.PARAMETER InputDir
  Dossier de la bibliothèque. Par défaut : music_in.

.PARAMETER OutputDir
  Dossier de sortie. Par défaut : music_out.

.PARAMETER BitrateKbps
  Débit MP3 en kbps. 192 par défaut.

.PARAMETER DryRun
  Affiche le plan sans encoder ni écrire de fichier.

.EXAMPLE
  .\tool\convert_audio.ps1

.EXAMPLE
  .\tool\convert_audio.ps1 -InputDir music_in -OutputDir music_out -BitrateKbps 160
#>
[CmdletBinding()]
param(
  [string]$InputDir = 'music_in',
  [string]$OutputDir = 'music_out',
  [ValidateRange(96, 320)]
  [int]$BitrateKbps = 192,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }

$audioExtensions = @(
  '.mp3', '.wav', '.flac', '.m4a', '.mp4', '.aac', '.ogg', '.oga', '.wma',
  '.aiff', '.aif', '.flv', '.mov', '.webm'
)
$imageExtensions = @('.jpg', '.jpeg', '.png', '.webp')

function Resolve-Tool {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $roots = @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'),
    (Join-Path $env:ProgramFiles 'ffmpeg')
  )
  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    $found = Get-ChildItem -LiteralPath $root -Recurse -Filter "$Name.exe" -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($found) { return $found.FullName }
  }
  return $null
}

function Remove-Diacritics {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
  $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
  $builder = New-Object Text.StringBuilder
  foreach ($ch in $normalized.ToCharArray()) {
    $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
    if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$builder.Append($ch)
    }
  }
  return $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
}

function Get-Slug {
  param([string]$Text, [string]$Fallback = 'track')
  $slug = (Remove-Diacritics $Text).ToLowerInvariant()
  $slug = [regex]::Replace($slug, '[^a-z0-9]+', '_').Trim('_')
  if ([string]::IsNullOrEmpty($slug)) { return $Fallback }
  return $slug
}

function Get-NormKey {
  param([string]$Text)
  $key = (Remove-Diacritics $Text).ToLowerInvariant()
  return [regex]::Replace($key, '[^a-z0-9]+', ' ').Trim()
}

function Get-Levenshtein {
  param([string]$A, [string]$B)
  if ($A -eq $B) { return 0 }
  if ([string]::IsNullOrEmpty($A)) { return $B.Length }
  if ([string]::IsNullOrEmpty($B)) { return $A.Length }

  $previous = New-Object int[] ($B.Length + 1)
  $current = New-Object int[] ($B.Length + 1)
  for ($j = 0; $j -le $B.Length; $j++) { $previous[$j] = $j }

  for ($i = 1; $i -le $A.Length; $i++) {
    $current[0] = $i
    for ($j = 1; $j -le $B.Length; $j++) {
      $cost = if ($A[$i - 1] -eq $B[$j - 1]) { 0 } else { 1 }
      $deletion = $current[$j - 1] + 1
      $insertion = $previous[$j] + 1
      $substitution = $previous[$j - 1] + $cost
      $current[$j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
    }
    $swap = $previous
    $previous = $current
    $current = $swap
  }
  return $previous[$B.Length]
}

function Test-WordMatch {
  param([string]$Left, [string]$Right)
  if ([string]::IsNullOrEmpty($Left) -or [string]::IsNullOrEmpty($Right)) { return $false }
  if ($Left -eq $Right) { return $true }
  if ($Left.Length -ge 4 -and $Right.Length -ge 4) {
    return (Get-Levenshtein $Left $Right) -le 2
  }
  return $false
}

function Test-ArtistLike {
  param([string]$Candidate, [string[]]$ArtistWords)
  $words = @($Candidate -split ' ' | Where-Object { $_ })
  if ($words.Count -eq 0) { return $false }
  $hits = 0
  foreach ($word in $words) {
    foreach ($artistWord in $ArtistWords) {
      if (Test-WordMatch $word $artistWord) { $hits++; break }
    }
  }
  $required = [Math]::Min($words.Count, [Math]::Max(1, $ArtistWords.Count))
  return $hits -ge $required
}

function Get-Compact {
  param([string]$Text)
  $compact = (Remove-Diacritics $Text).ToLowerInvariant()
  return [regex]::Replace($compact, '[^a-z0-9]', '')
}

function Test-CompactMatch {
  param([string]$Candidate, [string]$Alias)
  if ([string]::IsNullOrEmpty($Candidate) -or [string]::IsNullOrEmpty($Alias)) { return $false }
  if ($Candidate -eq $Alias) { return $true }
  if ($Alias.Length -ge 6 -and [Math]::Abs($Candidate.Length - $Alias.Length) -le 1) {
    return (Get-Levenshtein $Candidate $Alias) -le 2
  }
  return $false
}

function Remove-AliasPrefix {
  param([string[]]$Words, [string[]]$Aliases)
  foreach ($alias in $Aliases) {
    $aliasCompact = Get-Compact $alias
    if ([string]::IsNullOrEmpty($aliasCompact)) { continue }
    $aliasWordCount = @($alias -split '\s+' | Where-Object { $_ }).Count
    $max = [Math]::Min($Words.Count - 1, $aliasWordCount + 2)
    for ($n = 1; $n -le $max; $n++) {
      $candidate = Get-Compact (($Words[0..($n - 1)]) -join ' ')
      if (Test-CompactMatch $candidate $aliasCompact) {
        return @($Words[$n..($Words.Count - 1)])
      }
    }
  }
  return $Words
}

function Remove-AliasSuffix {
  param([string[]]$Words, [string[]]$Aliases)
  foreach ($alias in $Aliases) {
    $aliasCompact = Get-Compact $alias
    if ([string]::IsNullOrEmpty($aliasCompact)) { continue }
    $aliasWordCount = @($alias -split '\s+' | Where-Object { $_ }).Count
    $max = [Math]::Min($Words.Count - 1, $aliasWordCount + 2)
    for ($n = 1; $n -le $max; $n++) {
      $start = $Words.Count - $n
      $candidate = Get-Compact (($Words[$start..($Words.Count - 1)]) -join ' ')
      if (Test-CompactMatch $candidate $aliasCompact) {
        return @($Words[0..($start - 1)])
      }
    }
  }
  return $Words
}

function Get-CleanTitle {
  param([string]$FileName, [string]$Artist, [string[]]$Aliases)

  $original = $FileName
  $title = $FileName
  while ($title -match '\.(mp4|m4a|mp3|flv|aac|wav|flac|ogg|oga|wma|aiff|aif|mov|webm)$') {
    $title = [regex]::Replace($title, '\.(mp4|m4a|mp3|flv|aac|wav|flac|ogg|oga|wma|aiff|aif|mov|webm)$', '', 'IgnoreCase')
  }
  $title = $title -replace '_', ' '
  $title = [regex]::Replace($title, '\s+', ' ').Trim()

  # Préfixes parasites : année, pays, « Groupe ».
  $title = [regex]::Replace($title, '^\s*[\[\(]?\d{4}[\]\)]?\s*', '')
  $title = [regex]::Replace($title, '^\s*b[e\u00e9]nin\s*[-\u2013\u2014_:]*\s*', '', 'IgnoreCase')
  $title = [regex]::Replace($title, '^\s*groupe\s+', '', 'IgnoreCase')

  # Mentions entre parenthèses ou crochets : (Audio Officiel), [Clip Officiel], (Benin), (1)…
  $noise = '(?:audio|clip|officiel|official|vid[e\u00e9]o|live|version|remix|b[e\u00e9]nin|benin|1)'
  $title = [regex]::Replace($title, "\s*[\(\[]\s*$noise[^\)\]]*[\)\]]", '', 'IgnoreCase')
  # Suffixe pays : « … - Benin ».
  $title = [regex]::Replace($title, '\s*[-\u2013\u2014_]\s*b[e\u00e9]nin\s*$', '', 'IgnoreCase')
  # Pays isolé devant un titre entre parenthèses ou en fin de nom.
  $title = [regex]::Replace($title, '\s*\b(?:benin|b[e\u00e9]nin)\b\s*(?=[\(\[]|$)', '', 'IgnoreCase')
  $title = [regex]::Replace($title, '\s+', ' ').Trim()

  $artistKey = Get-NormKey $Artist
  $artistWords = @($artistKey -split ' ' | Where-Object { $_ })

  # « Artiste - Titre » ou « Artiste __ Titre ».
  $separator = [regex]::Match($title, '^(?<left>.*?)\s*(?:\s[-\u2013\u2014]\s|__+)\s*(?<right>.+)$')
  if ($separator.Success) {
    $leftKey = Get-NormKey $separator.Groups['left'].Value
    if ($leftKey -eq $artistKey -or (Test-ArtistLike $leftKey $artistWords)) {
      $title = $separator.Groups['right'].Value.Trim()
    }
  }

  # Retire le nom de l'artiste placé au début ou à la fin, avec ses variantes.
  $words = @($title -split ' ' | Where-Object { $_ })
  if ($words.Count -gt 1) {
    $words = @(Remove-AliasPrefix $words $Aliases)
    $words = @(Remove-AliasSuffix $words $Aliases)
    $title = ($words -join ' ')
  }

  $trimPattern = '^[\s\-\u2013\u2014_.,;:''"\u2018\u2019\u201c\u201d()]+'
  $trimEndPattern = '[\s\-\u2013\u2014_.,;:''"\u2018\u2019\u201c\u201d()]+$'
  $title = [regex]::Replace($title, $trimPattern, '').Trim()
  $title = [regex]::Replace($title, $trimEndPattern, '').Trim()

  # Titre entièrement entre parenthèses : « (Batia Bakam) » -> « Batia Bakam ».
  if ($title -match '^[\(\[]\s*(.+?)\s*[\)\]]$') {
    $title = $Matches[1].Trim()
  }
  $title = [regex]::Replace($title, $trimPattern, '').Trim()
  $title = [regex]::Replace($title, $trimEndPattern, '').Trim()

  if ([string]::IsNullOrWhiteSpace($title) -or (Get-NormKey $title) -eq $artistKey) {
    $fallback = $original
    while ($fallback -match '\.(mp4|m4a|mp3|flv|aac|wav|flac|ogg|oga|wma|aiff|aif|mov|webm)$') {
      $fallback = [regex]::Replace($fallback, '\.(mp4|m4a|mp3|flv|aac|wav|flac|ogg|oga|wma|aiff|aif|mov|webm)$', '', 'IgnoreCase')
    }
    $fallback = $fallback -replace '_', ' '
    $title = [regex]::Replace($fallback, '\s+', ' ').Trim()
  }

  return $title
}

function Read-TextFile {
  param([string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  $text = $null
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $text = [Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
  } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $text = [Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
  } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $text = [Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
  }
  if ($null -eq $text) {
    try {
      $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
      $text = $strictUtf8.GetString($bytes)
    } catch {
      $text = [Text.Encoding]::GetEncoding(1252).GetString($bytes)
    }
  }
  if ($text.Length -gt 0 -and [int]$text[0] -eq 0xFEFF) {
    $text = $text.Substring(1)
  }
  return $text
}

function Convert-Subtitle {
  param([string]$Path, [int64]$DurationMs)
  $raw = Read-TextFile $Path
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  $doc = $raw | ConvertFrom-Json
  if ($null -eq $doc.lyrics -or $null -eq $doc.lyrics.lines) { return $null }

  $syncType = [string]$doc.lyrics.syncType
  $lines = New-Object System.Collections.Generic.List[object]
  foreach ($line in @($doc.lyrics.lines)) {
    $text = [string]$line.words
    if ([string]::IsNullOrWhiteSpace($text)) { continue }
    $text = [regex]::Replace($text.Trim(), '\s+', ' ')
    $t = [int64]0
    [void][int64]::TryParse([string]$line.startTimeMs, [ref]$t)
    $lines.Add([pscustomobject]@{ t = $t; text = $text })
  }
  if ($lines.Count -eq 0) { return $null }

  $hasTiming = @($lines | Where-Object { $_.t -gt 0 }).Count -gt 0
  $synced = ($syncType -ne 'UNSYNCED') -and $hasTiming
  if (-not $synced -and $DurationMs -gt 0) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $lines[$i].t = [int64][Math]::Round($i * $DurationMs / [double]$lines.Count)
    }
  }

  return [pscustomobject]@{
    synced = $synced
    lines  = $lines
  }
}

function Write-LyricsJson {
  param([string]$Path, $Lines)
  $parts = foreach ($line in $Lines) {
    $textJson = ConvertTo-Json -InputObject ([string]$line.text) -Compress
    '    { "t": ' + $line.t + ', "text": ' + $textJson + ' }'
  }
  $json = "[`n" + ($parts -join ",`n") + "`n]`n"
  [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($false)))
}

function Format-Size {
  param([double]$Bytes)
  if ($Bytes -ge 1GB) { return ('{0:N2} Go' -f ($Bytes / 1GB)) }
  if ($Bytes -ge 1MB) { return ('{0:N1} Mo' -f ($Bytes / 1MB)) }
  return ('{0:N0} Ko' -f ($Bytes / 1KB))
}

function Get-MatchScore {
  param([string]$TitleKey, [string]$SubtitleKey)
  if ([string]::IsNullOrEmpty($TitleKey) -or [string]::IsNullOrEmpty($SubtitleKey)) { return 0 }
  if ($TitleKey -eq $SubtitleKey) { return 100 }
  if ($TitleKey.Contains($SubtitleKey) -or $SubtitleKey.Contains($TitleKey)) { return 85 }

  $titleWords = @($TitleKey -split ' ' | Where-Object { $_ } | Select-Object -Unique)
  $subtitleWords = @($SubtitleKey -split ' ' | Where-Object { $_ } | Select-Object -Unique)
  if ($titleWords.Count -eq 0 -or $subtitleWords.Count -eq 0) { return 0 }

  $common = 0
  foreach ($word in $titleWords) {
    if ($subtitleWords -contains $word) { $common++ }
  }
  $union = $titleWords.Count + $subtitleWords.Count - $common
  if ($union -le 0) { return 0 }
  return [int][Math]::Round(70 * $common / $union)
}

# ───────────────────────── Préparation ─────────────────────────

$ffmpeg = Resolve-Tool 'ffmpeg'
$ffprobe = Resolve-Tool 'ffprobe'
if (-not $ffmpeg -or -not $ffprobe) {
  Write-Host 'ffmpeg/ffprobe introuvable.' -ForegroundColor Yellow
  Write-Host 'Installe-le avec :'
  Write-Host '  winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements'
  Write-Host 'Ferme puis rouvre le terminal, et relance ce script.'
  exit 1
}

if (-not (Test-Path -LiteralPath $InputDir)) {
  New-Item -ItemType Directory -Path $InputDir | Out-Null
  Write-Host "Dossier cree : $InputDir" -ForegroundColor Green
  Write-Host "Place un sous-dossier par artiste, puis relance le script."
  exit 0
}

$artistDirs = @(Get-ChildItem -LiteralPath $InputDir -Directory | Sort-Object Name)
if ($artistDirs.Count -eq 0) {
  Write-Host "Aucun dossier d'artiste dans $InputDir." -ForegroundColor Yellow
  Write-Host 'Structure attendue : music_in/<Artiste>/<fichier audio>'
  exit 0
}

# Variantes connues du nom d'artiste dans les noms de fichiers.
$artistAliases = @{
  'Sagbohan'   = @('Sagbohan Danialou')
  'Baba Jahla' = @('Baba Djallah', 'Baba jah la')
  'Onel Mala'  = @("O'Nel Mala")
}

$audioOut = Join-Path $OutputDir 'audio'
$lyricsOut = Join-Path $OutputDir 'lyrics'
$coverOut = Join-Path $OutputDir 'covers'
if (-not $DryRun) {
  New-Item -ItemType Directory -Force -Path $audioOut | Out-Null
  New-Item -ItemType Directory -Force -Path $lyricsOut | Out-Null
  New-Item -ItemType Directory -Force -Path $coverOut | Out-Null
}

$usedIds = @{}
$rows = New-Object System.Collections.Generic.List[object]
$errors = 0
$index = 0
$warnings = New-Object System.Collections.Generic.List[string]
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

foreach ($artistDir in $artistDirs) {
  $artist = $artistDir.Name.Trim()
  if ([string]::IsNullOrWhiteSpace($artist)) { continue }

  $artistSlug = Get-Slug $artist

  $aliases = @($artist)
  if ($artistAliases.ContainsKey($artist)) {
    $aliases += $artistAliases[$artist]
  }
  $aliases = @($aliases | Sort-Object { (Get-Compact $_).Length } -Descending)

  $audioFiles = @(
    Get-ChildItem -LiteralPath $artistDir.FullName -File |
      Where-Object { $audioExtensions -contains $_.Extension.ToLowerInvariant() } |
      Sort-Object Name
  )
  if ($audioFiles.Count -eq 0) {
    $warnings.Add("Aucun fichier audio dans le dossier '$artist'.")
    continue
  }

  # Pochettes : première image du dossier, recadrée en 600 x 600.
  $coverSource = Get-ChildItem -LiteralPath $artistDir.FullName -File |
    Where-Object { $imageExtensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object Name |
    Select-Object -First 1
  $coverRelative = ''
  if ($coverSource) {
    $coverRelative = "covers/$artistSlug.jpg"
    if (-not $DryRun) {
      $coverFile = Join-Path $coverOut "$artistSlug.jpg"
      & $ffmpeg -hide_banner -loglevel error -y -i $coverSource.FullName `
        -vf 'scale=600:600:force_original_aspect_ratio=increase,crop=600:600' `
        -q:v 3 $coverFile
      if ($LASTEXITCODE -ne 0) {
        $warnings.Add("Pochette illisible pour '$artist' : $($coverSource.Name)")
        $coverRelative = ''
      }
    }
  }

  # Sous-titres du dossier (JSON Musixmatch).
  $subtitleFiles = @(
    Get-ChildItem -LiteralPath $artistDir.FullName -File -Filter *.json |
      Sort-Object Name
  )

  # Première passe : titres, identifiants, durées.
  $tracks = New-Object System.Collections.Generic.List[object]
  foreach ($file in $audioFiles) {
    $baseName = $file.Name
    $title = Get-CleanTitle $baseName $artist $aliases
    if ([string]::IsNullOrWhiteSpace($title)) { $title = $file.BaseName }

    $id = "${artistSlug}_$(Get-Slug $title)"
    if ($usedIds.ContainsKey($id)) {
      $usedIds[$id]++
      $id = "${id}_$($usedIds[$id])"
    } else {
      $usedIds[$id] = 1
    }

    $durationMs = [int64]0
    try {
      $probeJson = & $ffprobe -v error -show_entries 'format=duration' -of json $file.FullName 2>$null | Out-String
      $info = $probeJson | ConvertFrom-Json
      if ($null -ne $info.format.duration) {
        $durationMs = [int64][Math]::Round(([double]$info.format.duration) * 1000)
      }
    } catch {
      $warnings.Add("Duree illisible : $($file.Name)")
    }

    $tracks.Add([pscustomobject]@{
      File       = $file
      Title      = $title
      TitleKey   = Get-NormKey $title
      Id         = $id
      DurationMs = $durationMs
      Subtitle   = $null
      Synced     = $false
    })
  }

  # Association sous-titre -> morceau (au meilleur score, sans doublon).
  foreach ($subtitleFile in $subtitleFiles) {
    $subtitleBase = [IO.Path]::GetFileNameWithoutExtension($subtitleFile.Name)
    $subtitleKey = Get-NormKey $subtitleBase
    $bestTrack = $null
    $bestScore = 0
    foreach ($track in $tracks) {
      if ($null -ne $track.Subtitle) { continue }
      $score = Get-MatchScore $track.TitleKey $subtitleKey
      if ($score -gt $bestScore) {
        $bestScore = $score
        $bestTrack = $track
      }
    }
    if ($null -ne $bestTrack -and $bestScore -ge 50) {
      $bestTrack.Subtitle = $subtitleFile
      $bestTrack.Synced = $bestScore -ge 85
    } else {
      $warnings.Add("Sous-titre non associe : $artist/$($subtitleFile.Name)")
    }
  }

  # Deuxième passe : conversion audio + écriture des paroles.
  foreach ($track in $tracks) {
    $index++
    $percent = [int](($index - 1) / [Math]::Max(1, ($audioFiles.Count * $artistDirs.Count)) * 100)
    Write-Progress -Activity 'Conversion audio' `
      -Status "$index - $artist - $($track.Title)" `
      -PercentComplete $percent

    $audioRelative = "audio/$($track.Id).mp3"
    $audioFile = Join-Path $audioOut "$($track.Id).mp3"
    $lyricsRelative = ''

    if ($DryRun) {
      Write-Host ("[dry-run] {0}/{1}  ->  {2}  ({3})" -f $artist, $track.File.Name, $audioRelative, $track.Title) -ForegroundColor DarkGray
      if ($null -ne $track.Subtitle) {
        Write-Host ("           paroles <- {0}" -f $track.Subtitle.Name) -ForegroundColor DarkGray
      }
      continue
    }

    & $ffmpeg -hide_banner -loglevel error -y -i $track.File.FullName `
      -vn -map_metadata -1 `
      -metadata "title=$($track.Title)" -metadata "artist=$artist" `
      -c:a libmp3lame -b:a "$($BitrateKbps)k" -ar 44100 -ac 2 `
      -id3v2_version 3 $audioFile

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $audioFile)) {
      Write-Host ("  Echec : {0}/{1}" -f $artist, $track.File.Name) -ForegroundColor Red
      $errors++
      continue
    }

    # Paroles.
    if ($null -ne $track.Subtitle) {
      $subtitle = Convert-Subtitle $track.Subtitle.FullName $track.DurationMs
      if ($null -ne $subtitle) {
        $lyricsRelative = "lyrics/$($track.Id).json"
        $lyricsFile = Join-Path $lyricsOut "$($track.Id).json"
        Write-LyricsJson $lyricsFile $subtitle.lines
        $track.Synced = [bool]$subtitle.synced
      } else {
        $warnings.Add("Sous-titre vide : $artist/$($track.Subtitle.Name)")
      }
    }

    $outSize = (Get-Item -LiteralPath $audioFile).Length
    $rows.Add([pscustomobject]@{
      id               = $track.Id
      title            = $track.Title
      artist           = $artist
      duration_seconds = [int][Math]::Round($track.DurationMs / 1000.0)
      audio_path       = $audioRelative
      lyrics_path      = $lyricsRelative
      lyrics_synced    = if ($lyricsRelative) { [bool]$track.Synced } else { '' }
      cover_path       = $coverRelative
      size_kb          = [int][Math]::Round($outSize / 1KB)
      source_file      = "$artist/$($track.File.Name)"
    })

    $saved = if ($track.File.Length -gt 0) { (1 - ($outSize / $track.File.Length)) * 100 } else { 0 }
    Write-Host ("  {0} -> {1}  ({2} -> {3}, {4:N0} % de gagne)" -f `
        $track.File.Name, "$($track.Id).mp3", (Format-Size $track.File.Length), (Format-Size $outSize), $saved) `
      -ForegroundColor Green
  }
}

Write-Progress -Activity 'Conversion audio' -Completed
$stopwatch.Stop()

if ($DryRun) {
  Write-Host ''
  Write-Host 'Mode dry-run : aucun fichier encode.' -ForegroundColor Yellow
  exit 0
}

$csvPath = Join-Path $OutputDir 'manifest.csv'
$jsonPath = Join-Path $OutputDir 'manifest.json'
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$json = $rows | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText(
  $jsonPath,
  $json,
  (New-Object Text.UTF8Encoding($false))
)

$totalInput = 0
$totalOutput = 0
foreach ($row in $rows) {
  $source = Join-Path $InputDir $row.source_file
  if (Test-Path -LiteralPath $source) {
    $totalInput += (Get-Item -LiteralPath $source).Length
  }
  $totalOutput += $row.size_kb * 1KB
}

Write-Host ''
Write-Host 'Termine.' -ForegroundColor Cyan
Write-Host ("  Morceaux convertis : {0}" -f $rows.Count)
Write-Host ("  Sous-titres        : {0}" -f @($rows | Where-Object { $_.lyrics_path }).Count)
if ($errors -gt 0) {
  Write-Host ("  Echecs             : {0}" -f $errors) -ForegroundColor Red
}
if ($warnings.Count -gt 0) {
  Write-Host ''
  Write-Host 'Avertissements :' -ForegroundColor Yellow
  foreach ($warning in $warnings) { Write-Host "  - $warning" -ForegroundColor DarkYellow }
}
Write-Host ("  Entree             : {0}" -f (Format-Size $totalInput))
Write-Host ("  Sortie MP3         : {0}" -f (Format-Size $totalOutput))
if ($totalInput -gt 0) {
  Write-Host ("  Gain               : {0:N0} %" -f ((1 - ($totalOutput / $totalInput)) * 100))
}
Write-Host ("  Duree              : {0:N1} s" -f $stopwatch.Elapsed.TotalSeconds)
Write-Host ("  Manifest CSV       : {0}" -f $csvPath)
Write-Host ("  Manifest JSON      : {0}" -f $jsonPath)
