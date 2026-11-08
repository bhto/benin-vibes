# Bibliothèque et audio local

> L'application est entièrement autonome : métadonnées, pochettes, paroles et
> audio sont embarqués ou stockés localement. Aucune connexion n'est requise.

## Objectif

- **SQLite locale** : artistes, genres et morceaux, avec clés étrangères ;
- **assets compilés** : pochettes (`assets/covers/`), paroles
  (`assets/lyrics/`) et audio (`assets/audio/`) ;
- **lecture locale** : les MP3 sont lus directement depuis l'APK avec
  `just_audio`, sans streaming ni cache réseau.

L'APK contient donc les 37 MP3 (environ 262 Mo).

## Base SQLite locale

Le schéma est créé au premier lancement dans `lib/database/app_database.dart`,
puis rempli depuis `assets/data/library.json`.

```sql
CREATE TABLE genres (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  slug  TEXT NOT NULL UNIQUE,
  name  TEXT NOT NULL UNIQUE,
  color TEXT NOT NULL,
  icon  TEXT NOT NULL
);

CREATE TABLE artists (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  slug       TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL UNIQUE,
  cover_path TEXT,
  tint       TEXT NOT NULL
);

CREATE TABLE tracks (
  id               TEXT PRIMARY KEY,
  title            TEXT NOT NULL,
  artist_id        INTEGER NOT NULL,
  genre_id         INTEGER NOT NULL,
  position         INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
  audio_path       TEXT NOT NULL,
  cover_path       TEXT,
  lyrics_path      TEXT,
  lyrics_synced    INTEGER NOT NULL DEFAULT 0
                   CHECK (lyrics_synced IN (0, 1)),
  liked            INTEGER NOT NULL DEFAULT 0
                   CHECK (liked IN (0, 1)),
  FOREIGN KEY (artist_id) REFERENCES artists (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (genre_id) REFERENCES genres (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE (artist_id, title)
);
```

Le schéma est en version 2 : une base version 1 créée par une ancienne
installation reçoit la colonne `liked` via `onUpgrade`, sans perdre la
bibliothèque. `MusicRepository.setLiked()` met ce drapeau à jour, et
`loadLibrary()` le relit dans `Track.liked`.

`PRAGMA foreign_keys = ON` est exécuté à chaque ouverture. Les suppressions
d'artiste ou de genre encore utilisés sont donc refusées.

### Accueil aléatoire

`MusicRepository.loadLibrary()` tire « À la une » (5 morceaux) et
« Nouveautés » (10 morceaux) directement dans SQLite avec `ORDER BY RANDOM()`.
Le reste de la bibliothèque conserve l'ordre `position`.

### Seed

`assets/data/library.json` est généré depuis le manifest de conversion :

```powershell
.\tool\build_library_seed.ps1
```

Le script :

1. lit `music_out/manifest.json` ;
2. attribue un genre à chaque morceau (la table de correspondance est
   explicite dans le script) ;
3. copie les pochettes, paroles et MP3 dans `assets/` ;
4. écrit `assets/data/library.json`.

Si SQLite n'est pas disponible (par exemple sur le bureau), l'application
retombe sur le même seed via `MusicRepository.loadFromSeed()`.

## Taxonomie des genres

Six genres couvrent les 37 morceaux actuels :

| Slug | Libellé | Morceaux |
|---|---|---|
| `afro-folk` | Afro-folk | Afafa (2), Kiri Kanta (5) |
| `afropop` | Afropop | Angélique Kidjo (3), Petit Miguelito (5) |
| `gospel` | Gospel | Anna Teko (3), Johnny Sourou (5), Onel Mala (3) |
| `traditionnel` | Traditionnel | Baba Jahla (4), Sagbohan Danialou (5) |
| `world` | World | Angélique Kidjo — Malaika |
| `tchink` | Tchink System | Afafa — Tchité |

## Convention de stockage

```text
assets/
├── audio/
│   ├── afafa_ne_jamais_reculer.mp3
│   ├── angelique_kidjo_batonga.mp3
│   └── ...
├── covers/
│   ├── afafa.jpg
│   └── ...
├── lyrics/
│   ├── angelique_kidjo_agolo.json
│   └── ...
└── data/
    └── library.json
```

`{fichier}` est un identifiant stable de type `artiste_titre`, ex.
`angelique_kidjo_agolo`.

## Lecture audio

1. `AudioSourceResolver` cherche d'abord un éventuel MP3 dans le stockage
   externe de l'app (pratique pour tester un fichier sans rebuilder), puis
   utilise l'asset embarqué `assets/audio/<fichier>.mp3` ;
2. `JustAudioEngine` charge l'asset avec `setAsset` ;
3. `PlayerController` utilise la position, la durée et l'état réels du moteur,
   avec enchaînement automatique du morceau suivant ;
4. si aucune source n'est disponible, la progression est simulée pour garder
   l'interface utilisable.

**Sur le web**, `just_audio` charge un asset en lisant tout le MP3 avec
`rootBundle` puis en le convertissant en data URL base64. Pour un fichier de
plusieurs mégaoctets, ce transfert est lent et deux changements de titre
rapprochés peuvent se chevaucher : l'ancienne piste continue alors de jouer
alors que l'interface affiche la nouvelle. `JustAudioEngine` sert donc
directement l'asset statique (`assets/assets/audio/...`) au navigateur, qui le
streame. En cas d'URL injouable, il retombe sur `setAsset`.

**Changements de source sérialisés.** `SourceSwitchQueue` exécute un seul
chargement à la fois et ignore une demande remplacée avant son démarrage. Le
contrôleur ignore en outre les événements « en pause » émis par le moteur
pendant un chargement, pour ne pas annuler l'intention de lecture.

**Cache des assets.** `just_audio` extrait chaque MP3 dans un fichier
temporaire et ne le remplace pas quand l'APK est mis à jour. Sans nettoyage,
l'ancienne version d'un morceau peut donc continuer à être lue après une
recompilation. `JustAudioEngine.clearAssetCache()` est appelé au démarrage
dans `main.dart` pour supprimer ces copies et forcer la relecture depuis
l'APK.

Au premier lancement, aucun morceau n'est sélectionné : le mini-lecteur reste
masqué jusqu'au premier choix de l'utilisateur.

## Conversion des fichiers

```powershell
.\tool\convert_audio.ps1
```

- Entrée : `music_in/<Artiste>/` (m4a, mp4, mp3, wav, flac…).
- Sortie : `music_out/audio/artiste_titre.mp3` en **MP3 192 kbps**.
- Pochettes d'artiste recadrées en 600 × 600 dans `music_out/covers/`.
- Sous-titres convertis en `music_out/lyrics/artiste_titre.json`, au format
  `[{ "t": <millisecondes>, "text": "..." }]`.
- `manifest.csv` et `manifest.json` servent de source au seed local.

Détails et options : `tool/README.md`.

## Points d'attention

- **Poids de l'APK** : les 37 MP3 représentent environ 262 Mo.
- **Hors ligne** : toutes les fonctionnalités sont disponibles sans réseau.
- **Droits** : ne distribuer que des morceaux dont les ayants droit ont
  autorisé la diffusion.
