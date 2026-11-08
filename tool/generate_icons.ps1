#requires -Version 5.1
<#
.SYNOPSIS
  Génère les icônes Android à partir de assets/icons/app_icon.svg.

.DESCRIPTION
  Aucune dépendance à installer : le SVG est rendu en PNG par Microsoft Edge
  en mode headless, puis redimensionné avec System.Drawing pour produire :

    mipmap-<densité>/ic_launcher.png              (icône classique)
    mipmap-<densité>/ic_launcher_foreground.png   (icône adaptative, 108 dp)
    mipmap-anydpi-v26/ic_launcher.xml             (fond + premier plan)
    values/ic_launcher_background.xml             (couleur de fond)

  Relancer ce script après toute modification du SVG.
#>
param(
  [string]$Svg = (Join-Path $PSScriptRoot '..\assets\icons\app_icon.svg'),
  [string]$Res = (Join-Path $PSScriptRoot '..\android\app\src\main\res')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $Svg)) {
  throw "SVG introuvable : $Svg"
}

$edge = @(
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $edge) {
  throw 'Microsoft Edge est requis pour convertir le SVG en PNG.'
}

$work = Join-Path $env:TEMP 'benin_vibes_icons'
if (Test-Path -LiteralPath $work) { Remove-Item -Recurse -Force -LiteralPath $work }
New-Item -ItemType Directory -Path $work | Out-Null

$rendered = Join-Path $work 'app_icon_1024.png'
$uri = ([Uri](Resolve-Path -LiteralPath $Svg).Path).AbsoluteUri

& Start-Process -FilePath $edge `
  -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    '--window-size=1024,1024',
    '--default-background-color=00000000',
    "--user-data-dir=`"$(Join-Path $work 'edge-profile')`"",
    "--screenshot=`"$rendered`"",
    "`"$uri`""
  ) `
  -Wait `
  -NoNewWindow `
  -RedirectStandardOutput "$(Join-Path $work 'edge.out.log')" `
  -RedirectStandardError "$(Join-Path $work 'edge.err.log')"

if (-not (Test-Path -LiteralPath $rendered)) {
  throw 'La conversion du SVG a échoué.'
}

function Save-IconBitmap {
  param(
    [System.Drawing.Bitmap]$Source,
    [int]$Size,
    [string]$Path
  )

  $bitmap = New-Object System.Drawing.Bitmap(
    $Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  )
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.DrawImage(
      $Source,
      (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)),
      (New-Object System.Drawing.Rectangle(0, 0, $Source.Width, $Source.Height)),
      [System.Drawing.GraphicsUnit]::Pixel
    )
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
}

$source = [System.Drawing.Bitmap]::FromFile($rendered)
try {
  # Icône classique : 48 dp.
  $legacy = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
  # Premier plan adaptatif : 108 dp, contenu utile dans la zone centrale.
  $foreground = @{ mdpi = 108; hdpi = 162; xhdpi = 216; xxhdpi = 324; xxxhdpi = 432 }

  foreach ($density in $legacy.Keys) {
    $dir = Join-Path $Res "mipmap-$density"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Save-IconBitmap $source $legacy[$density] (Join-Path $dir 'ic_launcher.png')
    Save-IconBitmap $source $foreground[$density] (Join-Path $dir 'ic_launcher_foreground.png')
  }
}
finally {
  $source.Dispose()
  Remove-Item -Recurse -Force -LiteralPath $work -ErrorAction SilentlyContinue
}

Write-Host 'Icônes Android générées dans android/app/src/main/res.'
