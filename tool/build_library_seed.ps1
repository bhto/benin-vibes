#requires -Version 5.1
<#
.SYNOPSIS
  Construit le seed de la bibliothèque locale à partir du manifest de conversion.

.DESCRIPTION
  Lit music_out/manifest.json, attribue un genre à chaque morceau, copie les
  pochettes et les paroles dans les assets de l'application, puis écrit
  assets/data/library.json.

  Le seed est la source unique utilisée pour remplir la base SQLite locale au
  premier lancement. L'audio reste distant ; seules les métadonnées, les
  pochettes et les paroles sont embarquées dans l'application.

  La table de correspondance des genres est volontairement explicite : chaque
  nouveau morceau doit y être ajouté, sinon le script échoue.

.PARAMETER ManifestPath
  Manifest produit par tool/convert_audio.ps1.

.PARAMETER CoversDir
  Dossier des pochettes converties.

.PARAMETER LyricsDir
  Dossier des paroles converties.

.PARAMETER OutputPath
  Fichier de seed à écrire.

.EXAMPLE
  .\tool\build_library_seed.ps1
#>
[CmdletBinding()]
param(
  [string]$ManifestPath = 'music_out/manifest.json',
  [string]$CoversDir = 'music_out/covers',
  [string]$LyricsDir = 'music_out/lyrics',
  [string]$OutputPath = 'assets/data/library.json',
  [string]$AssetsCovers = 'assets/covers',
  [string]$AssetsLyrics = 'assets/lyrics'
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }

# ───────────────────────── Taxonomie des genres ─────────────────────────
# Chaque genre possède un slug stable, un libellé, une couleur et une icône
# Material (clé résolue côté Flutter dans lib/data.dart).

$genres = @(
  [pscustomobject]@{ slug = 'afro-folk';    name = 'Afro-folk';    color = '#2FB36D'; icon = 'nature_people' }
  [pscustomobject]@{ slug = 'afropop';      name = 'Afropop';      color = '#E0447C'; icon = 'album' }
  [pscustomobject]@{ slug = 'gospel';       name = 'Gospel';       color = '#6A4CFF'; icon = 'church' }
  [pscustomobject]@{ slug = 'traditionnel'; name = 'Traditionnel'; color = '#E8833A'; icon = 'festival' }
  [pscustomobject]@{ slug = 'world';        name = 'World';        color = '#00A3A3'; icon = 'public' }
  [pscustomobject]@{ slug = 'tchink';       name = 'Tchink System'; color = '#D93A4A'; icon = 'waves' }
)

# Genre attribué à chaque identifiant de morceau.
$genreByTrack = @{
  'afafa_ne_jamais_reculer'                  = 'afro-folk'
  'afafa_tchite'                             = 'tchink'
  'afafa_alafia'                             = 'afro-folk'

  'angelique_kidjo_agolo'                    = 'afropop'
  'angelique_kidjo_batonga'                  = 'afropop'
  'angelique_kidjo_malaika_africa_live_in_dakar' = 'world'
  'angelique_kidjo_wombo_lombo'              = 'afropop'

  'anna_teko_au_pied_de_ta_croix'            = 'gospel'
  'anna_teko_roi_mysterieux'                 = 'gospel'
  'anna_teko_shilo'                          = 'gospel'

  'baba_jahla_batia_bakam'                   = 'traditionnel'
  'baba_jahla_yekidja'                       = 'traditionnel'
  'baba_jahla_amousoro'                      = 'traditionnel'
  'baba_jahla_nayihoue'                      = 'traditionnel'

  'johnny_sourou_avimademe'                  = 'gospel'
  'johnny_sourou_akonkpikpan'                = 'gospel'
  'johnny_sourou_houhlon_te_hounmen'         = 'gospel'
  'johnny_sourou_menuwe_sogandiwe'           = 'gospel'
  'johnny_sourou_ogbe_to_jesu_me'            = 'gospel'

  'kiri_kanta_gangangan'                     = 'afro-folk'
  'kiri_kanta_abiti'                         = 'afro-folk'
  'kiri_kanta_iyin_mindassan'                = 'afro-folk'
  'kiri_kanta_la_diva_africaine'             = 'afro-folk'
  'kiri_kanta_sourou'                        = 'afro-folk'

  'onel_mala_dieu_est_bon'                   = 'gospel'
  'onel_mala_lousha'                         = 'gospel'
  'onel_mala_vetu_de_gloire'                 = 'gospel'

  'petit_miguelito_zizi_yawo_kpankeke'       = 'afropop'
  'petit_miguelito_petit_a_petit'            = 'afropop'
  'petit_miguelito_c_est_avec_plaisir'       = 'afropop'
  'petit_miguelito_comme_ami'                = 'afropop'
  'petit_miguelito_gbemeho'                  = 'afropop'

  'sagbohan_tres_incorrecte'                 = 'traditionnel'
  'sagbohan_adjimevi'                        = 'traditionnel'
  'sagbohan_amon_noude_houn_dou'             = 'traditionnel'
  'sagbohan_mari_incapable'                  = 'traditionnel'
  'sagbohan_zemihin'                         = 'traditionnel'
}

# Métadonnées d'artiste : slug stable, nom affiché et teinte d'ambiance.
$artistMeta = @{
  'Afafa'            = @{ slug = 'afafa';            name = 'Afafa';            tint = '#E0447C' }
  'Angelique Kidjo'  = @{ slug = 'angelique_kidjo';  name = 'Angélique Kidjo';  tint = '#E8833A' }
  'Anna Teko'        = @{ slug = 'anna_teko';        name = 'Anna Teko';        tint = '#6A4CFF' }
  'Baba Jahla'       = @{ slug = 'baba_jahla';       name = 'Baba Jahla';       tint = '#00A3A3' }
  'Johnny Sourou'    = @{ slug = 'johnny_sourou';    name = 'Johnny Sourou';    tint = '#D93A4A' }
  'Kiri Kanta'       = @{ slug = 'kiri_kanta';       name = 'Kiri Kanta';       tint = '#B8860B' }
  'Onel Mala'        = @{ slug = 'onel_mala';        name = 'Onel Mala';        tint = '#8B5CF6' }
  'Petit Miguelito'  = @{ slug = 'petit_miguelito';  name = 'Petit Miguelito';  tint = '#4E77B8' }
  'Sagbohan'         = @{ slug = 'sagbohan';         name = 'Sagbohan Danialou'; tint = '#2E7D32' }
}

# ───────────────────────── Préparation ─────────────────────────

$manifestFullPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = [IO.File]::ReadAllText($manifestFullPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
if (-not $manifest -or $manifest.Count -eq 0) {
  throw "Manifest vide ou introuvable : $ManifestPath"
}

$genreSlugs = @($genres | ForEach-Object { $_.slug })
$missingGenres = @($manifest | Where-Object { -not $genreByTrack.ContainsKey($_.id) })
if ($missingGenres.Count -gt 0) {
  $ids = ($missingGenres | ForEach-Object { $_.id }) -join ', '
  throw "Aucun genre défini pour : $ids"
}

$unknownGenres = @($genreByTrack.Values | Where-Object { $genreSlugs -notcontains $_ } | Select-Object -Unique)
if ($unknownGenres.Count -gt 0) {
  throw "Genre(s) inconnu(s) dans la table de correspondance : $($unknownGenres -join ', ')"
}

# Vérifie que chaque artiste du manifest possède des métadonnées.
$missingArtists = @($manifest | ForEach-Object { $_.artist } | Select-Object -Unique |
  Where-Object { -not $artistMeta.ContainsKey($_) })
if ($missingArtists.Count -gt 0) {
  throw "Métadonnées manquantes pour l'artiste : $($missingArtists -join ', ')"
}

foreach ($dir in @($AssetsCovers, $AssetsLyrics, (Split-Path -Parent $OutputPath))) {
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
}

# Copie des pochettes et des paroles dans les assets compilés.
if (Test-Path -LiteralPath $CoversDir) {
  Get-ChildItem -LiteralPath $CoversDir -File -Filter *.jpg |
    Copy-Item -Destination $AssetsCovers -Force
}
if (Test-Path -LiteralPath $LyricsDir) {
  Get-ChildItem -LiteralPath $LyricsDir -File -Filter *.json |
    Copy-Item -Destination $AssetsLyrics -Force
}

# ───────────────────────── Construction du seed ─────────────────────────

$artists = New-Object System.Collections.Generic.List[object]
$seenArtists = @{}
foreach ($artistName in ($manifest | ForEach-Object { $_.artist } | Sort-Object -Unique)) {
  $meta = $artistMeta[$artistName]
  $coverFile = Join-Path $AssetsCovers "$($meta.slug).jpg"
  $coverPath = if (Test-Path -LiteralPath $coverFile) { "assets/covers/$($meta.slug).jpg" } else { $null }

  $artists.Add([pscustomobject]@{
    slug       = $meta.slug
    name       = $meta.name
    cover_path = $coverPath
    tint       = $meta.tint
  })
  $seenArtists[$artistName] = $meta.slug
}

$tracks = New-Object System.Collections.Generic.List[object]
$position = 0
foreach ($row in $manifest) {
  $artistSlug = $seenArtists[$row.artist]
  $genreSlug = $genreByTrack[$row.id]

  $coverPath = $null
  if ($row.cover_path) {
    $coverFile = Split-Path $row.cover_path -Leaf
    if (Test-Path -LiteralPath (Join-Path $AssetsCovers $coverFile)) {
      $coverPath = "assets/covers/$coverFile"
    }
  }

  $lyricsPath = $null
  if ($row.lyrics_path) {
    $lyricsFile = Split-Path $row.lyrics_path -Leaf
    $lyricsAsset = Join-Path $AssetsLyrics $lyricsFile
    if (-not (Test-Path -LiteralPath $lyricsAsset)) {
      throw "Paroles manquantes pour $($row.id) : $($row.lyrics_path)"
    }
    $lyricsPath = "assets/lyrics/$lyricsFile"
  }

  $tracks.Add([pscustomobject]@{
    id               = $row.id
    title            = $row.title
    artist           = $artistSlug
    genre            = $genreSlug
    duration_seconds = [int]$row.duration_seconds
    audio_path       = $row.audio_path
    cover_path       = $coverPath
    lyrics_path      = $lyricsPath
    lyrics_synced    = if ($lyricsPath) { [bool]$row.lyrics_synced } else { $false }
    position         = $position
  })
  $position++
}

$library = [ordered]@{
  genres  = $genres
  artists = $artists
  tracks  = $tracks
}

$json = $library | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText(
  (Join-Path (Get-Location) $OutputPath),
  $json,
  (New-Object Text.UTF8Encoding($false))
)

Write-Host 'Seed de la bibliothèque créé.' -ForegroundColor Cyan
Write-Host ("  Genres    : {0}" -f $genres.Count)
Write-Host ("  Artistes  : {0}" -f $artists.Count)
Write-Host ("  Morceaux  : {0}" -f $tracks.Count)
Write-Host ("  Paroles   : {0}" -f @($tracks | Where-Object { $_.lyrics_path }).Count)
Write-Host ("  Fichier   : {0}" -f $OutputPath)
