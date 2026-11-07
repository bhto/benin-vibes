# Conversion audio pour Supabase

Ce dossier contient le script qui prépare les morceaux avant l'envoi sur
Supabase Storage. Il ne télécharge rien et ne modifie pas les fichiers
d'origine.

## Format choisi

**AAC-LC en `.m4a`**, 128 kbps par défaut.

| Format | Taille approx. (4 min) | Android | iOS | Seek |
|---|---|---|---|---|
| MP3 320 kbps | ~9,5 Mo | oui | oui | oui |
| MP3 192 kbps | ~5,7 Mo | oui | oui | oui |
| **AAC 128 kbps (.m4a)** | **~3,8 Mo** | **oui** | **oui** | **oui** |
| AAC 96 kbps (.m4a) | ~2,9 Mo | oui | oui | oui |
| Opus 96 kbps (.ogg) | ~2,9 Mo | oui | **non** | oui |

AAC est le meilleur compromis : deux fois plus léger qu'un MP3 320, compatible
partout, et l'option `+faststart` permet de commencer la lecture et de se
déplacer dans le morceau avant la fin du téléchargement.

> Éviter de descendre sous 96 kbps pour de la musique. Si la source est déjà un
> MP3 compressé, partir d'un WAV/FLAC donne un meilleur résultat.

## Prérequis

`ffmpeg` et `ffprobe` doivent être dans le `PATH`.

```powershell
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
```

Ferme puis rouvre le terminal après l'installation, et vérifie :

```powershell
ffmpeg -version
```

## Utilisation

1. Place tes fichiers dans `music_in/` (mp3, wav, flac, m4a…).
2. Les pochettes sont optionnelles :
   - à côté du morceau : `music_in/ma-chanson.jpg` ;
   - ou dans `music_in/covers/` avec le nom du morceau.
3. Lance :

```powershell
.\tool\convert_audio.ps1
```

Résultat :

```
music_out/
├── audio/
│   ├── ma-chanson.m4a
│   └── ...
├── covers/
│   ├── ma-chanson.jpg   (600 × 600, si une pochette a été fournie)
│   └── ...
├── manifest.csv
└── manifest.json
```

Options utiles :

```powershell
# Version plus légère
.\tool\convert_audio.ps1 -BitrateKbps 96

# Simuler sans encoder
.\tool\convert_audio.ps1 -DryRun

# Dossiers personnalisés
.\tool\convert_audio.ps1 -InputDir mes-mp3 -OutputDir sortie
```

Si PowerShell bloque l'exécution :

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\convert_audio.ps1
```

## Manifest

Chaque ligne de `manifest.csv` / `manifest.json` contient :

- `id` : identifiant slug stable (ex. `zinli-night`) ;
- `title`, `artist` : lus dans les tags, sinon déduits du nom de fichier ;
- `duration_seconds` : durée réelle calculée par `ffprobe` ;
- `audio_path`, `cover_path` : chemins relatifs dans le bucket ;
- `size_kb`, `source_file`.

Ces informations correspondent aux colonnes proposées dans
`SUPABASE_NOTES.md`.

## Envoi sur Supabase

1. Envoie `music_out/audio/*.m4a` dans le bucket, sous `audio/`.
2. Envoie `music_out/covers/*.jpg` sous `covers/`.
3. Vérifie le **Content-Type** :
   - audio : `audio/mp4`
   - pochettes : `image/jpeg`
4. Importe `manifest.csv` dans la table `tracks` (ou génère les `INSERT` à
   partir du JSON).
5. Les URLs publiques ressemblent à :

```
https://<projet>.supabase.co/storage/v1/object/public/music/audio/zinli-night.m4a
```

## Droits

Ne convertir et n'héberger que des morceaux dont tu détiens les droits de
diffusion, ou pour lesquels tu as l'accord des artistes/ayants droit.
