# Conversion de la bibliothèque audio

Le script `tool/convert_audio.ps1` prépare les morceaux et leurs assets avant
l'intégration dans l'application. Il ne modifie jamais les fichiers d'origine.

## Structure d'entrée

Un sous-dossier par artiste. Le nom du dossier devient le nom de l'artiste.

```
music_in/
├── Angelique Kidjo/
│   ├── Angelique Kidjo - Agolo.mp4
│   ├── Angelique Kidjo - Batonga.mp4
│   ├── agolo.json                  ← sous-titre (optionnel)
│   └── Angelique Kidjo.jpg         ← pochette (optionnelle)
├── Onel Mala/
│   ├── Dieu est Bon - Onel Mala.mp4
│   ├── dieu_est_bon.json
│   └── O'Nel Mala.jpg
└── ...
```

Formats audio acceptés : `.m4a`, `.mp4`, `.mp3`, `.wav`, `.flac`, `.aac`,
`.ogg`, `.wma`, `.aiff`, `.flv`, `.mov`, `.webm`. Les vidéos sont traitées
comme des sources audio (la piste vidéo est ignorée).

## Structure de sortie

```
music_out/
├── audio/
│   ├── angelique_kidjo_agolo.mp3
│   └── ...
├── lyrics/
│   ├── angelique_kidjo_agolo.json
│   └── ...
├── covers/
│   ├── angelique_kidjo.jpg          ← 600 × 600
│   └── ...
├── manifest.csv
└── manifest.json
```

Le nom de fichier suit le format **`artiste_titre.mp3`** (minuscules, sans
accents, séparateur `_`). Il est identique pour le JSON de paroles :
**`artiste_titre.json`**. On retrouve donc directement le fichier à partir de
l'artiste et du titre.

Le préfixe artiste et les mentions parasites (`Audio Officiel`,
`Clip Officiel`, `Benin`, année entre crochets, `(1)`…) sont retirés du titre.
Les variantes connues (`Baba Djallah` pour `Baba Jahla`, `Sagbohan Danialou`
pour `Sagbohan`, `O'Nel Mala` pour `Onel Mala`) sont gérées.

## Format audio

**MP3 192 kbps**, 44,1 kHz, stéréo, tags ID3 `title` et `artist`.

| Débit | Taille approx. (4 min) |
|---|---|
| MP3 192 kbps | ~5,7 Mo |
| MP3 160 kbps | ~4,8 Mo |
| MP3 128 kbps | ~3,8 Mo |

Pour alléger l'ensemble :

```powershell
.\tool\convert_audio.ps1 -BitrateKbps 160
```

## Sous-titres JSON

Les fichiers d'entrée au format Musixmatch (`lyrics.lines[].startTimeMs` /
`words`) sont convertis en lignes horodatées, directement exploitables par
l'app :

```json
[
    { "t": 1920, "text": "Vêtu de gloire" },
    { "t": 5990, "text": "Le fils de l'homme reviendra" }
]
```

- `t` est en **millisecondes**.
- Les lignes vides sont ignorées.
- Un sous-titre `UNSYNCED` (tous les temps à 0) est réparti uniformément sur la
  durée du morceau ; `lyrics_synced` vaut alors `false` dans le manifest.
- L'association sous-titre → morceau se fait par similarité de titre
  (`agolo.json` → `Agolo`, `au pied de ta croix.json` →
  `AU PIED DE TA CROIX D'ANNA TEKO`). Un sous-titre non associé est signalé.
- Toutes les musiques n'ont pas de sous-titre : c'est optionnel.

## Prérequis

`ffmpeg` et `ffprobe` doivent être installés.

```powershell
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
```

Le script retrouve automatiquement `ffmpeg`/`ffprobe` dans le dossier
d'installation WinGet, même si le `PATH` n'est pas encore rechargé.

## Utilisation

```powershell
# Conversion complète
.\tool\convert_audio.ps1

# Vérifier le plan sans encoder
.\tool\convert_audio.ps1 -DryRun

# Débit plus léger
.\tool\convert_audio.ps1 -BitrateKbps 160

# Dossiers personnalisés
.\tool\convert_audio.ps1 -InputDir autre_entree -OutputDir autre_sortie
```

Si PowerShell bloque l'exécution :

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\convert_audio.ps1
```

## Manifest

Chaque ligne de `manifest.csv` / `manifest.json` contient :

- `id` : identifiant slug, ex. `angelique_kidjo_agolo` ;
- `title`, `artist` : déduits des noms de dossier et de fichier ;
- `duration_seconds` : durée réelle calculée par `ffprobe` ;
- `audio_path` : ex. `audio/angelique_kidjo_agolo.mp3` ;
- `lyrics_path` : ex. `lyrics/angelique_kidjo_agolo.json`, vide si absent ;
- `lyrics_synced` : `true`/`false` pour les paroles, vide sans paroles ;
- `cover_path` : ex. `covers/angelique_kidjo.jpg` ;
- `size_kb`, `source_file`.

## Seed de la bibliothèque locale

Une fois la conversion terminée, génère le seed SQLite et copie les assets
embarqués dans l'application :

```powershell
.\tool\build_library_seed.ps1
```

Le script :

- lit `music_out/manifest.json` ;
- attribue un genre à chaque morceau via une table de correspondance explicite
  (un morceau sans genre fait échouer la génération) ;
- copie les pochettes dans `assets/covers/` ;
- copie les paroles dans `assets/lyrics/` ;
- écrit `assets/data/library.json`, utilisé pour remplir la base SQLite au
  premier lancement.

Après une modification du script de conversion, relance donc les deux scripts :

```powershell
.\tool\convert_audio.ps1
.\tool\build_library_seed.ps1
```

## Intégration dans l'application

Le script `tool/build_library_seed.ps1` copie les sorties utiles dans `assets/` :

1. `music_out/audio/*.mp3` → `assets/audio/`
2. `music_out/lyrics/*.json` → `assets/lyrics/`
3. `music_out/covers/*.jpg` → `assets/covers/`
4. métadonnées → `assets/data/library.json`

`assets/audio/` est déclaré dans `pubspec.yaml` : les MP3 sont donc embarqués
dans l'APK et lus localement, sans réseau.

## Droits

Ne convertir et n'héberger que des morceaux dont tu détiens les droits de
diffusion, ou pour lesquels tu as l'accord des artistes/ayants droit.
