# Supabase — stockage des musiques (à brancher plus tard)

> Note interne. Rien n'est encore branché dans l'app : ce fichier sert de cahier
> des charges pour l'intégration Supabase Storage + `just_audio`.

## Objectif

Garder l'application légère : les fichiers audio et les pochettes vivent dans
Supabase Storage, l'app ne télécharge que ce qu'elle lit (streaming), avec un
cache local optionnel pour les pochettes.

## Ce que l'utilisateur doit fournir

- [ ] URL du projet : `https://<project-ref>.supabase.co`
- [ ] Nom du bucket (ex. `music`)
- [ ] Bucket public ou privé
- [ ] Structure de la table `tracks` (ou une ligne d'exemple en JSON)
- [ ] Clé `anon` publique — **jamais** la clé `service_role` dans l'app
- [ ] Un exemple de fichier : chemin, taille, format (MP3, M4A, AAC…)

## Convention proposée

```
music/
├── audio/
│   ├── {id}.m4a
│   └── ...
└── covers/
    ├── {id}.jpg
    └── ...
```

`{id}` est un identifiant stable (slug ou UUID) fourni par l'utilisateur.

URL publique d'un morceau :

```
{SUPABASE_URL}/storage/v1/object/public/music/audio/{id}.m4a
```

## Schéma SQL proposé

```sql
create table if not exists public.tracks (
  id           text primary key,
  title        text not null,
  artist       text not null,
  album        text,
  duration     integer,              -- secondes
  audio_path   text not null,        -- ex. audio/zinli-night.m4a
  cover_path   text,                 -- ex. covers/zinli-night.jpg
  tint         text,                 -- ex. #E0447C
  lyrics       jsonb,                -- [{ "t": 0, "text": "..." }, ...]
  created_at   timestamptz not null default now()
);

alter table public.tracks enable row level security;

-- Lecture publique de la table (bucket public)
create policy "tracks are readable"
  on public.tracks for select
  using (true);
```

> Si le bucket est privé, les fichiers passent par des URLs signées
> (`createSignedUrl`) et il faudra gérer leur expiration avant lecture.

## Conversion des fichiers

Un script local prépare les morceaux avant l'envoi :

```powershell
.\tool\convert_audio.ps1
```

- Entrée : `music_in/` (mp3, wav, flac…).
- Sortie : `music_out/audio/*.m4a` en **AAC-LC 128 kbps**, `+faststart`.
- Pochettes recadrées en 600 × 600 dans `music_out/covers/`.
- `manifest.csv` et `manifest.json` prêts pour la table `tracks`.

Détails et options : `tool/README.md`.

Content-Type à vérifier sur Supabase : `audio/mp4` pour les `.m4a`,
`image/jpeg` pour les pochettes.

## Plan d'intégration Flutter

1. `lib/config.dart` : URL + clé `anon` lues via
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
   Aucune clé écrite en dur dans le dépôt.
2. `lib/track_repository.dart` : lecture de `tracks` via l'API REST
   (`/rest/v1/tracks?select=*`), avec un client HTTP simple (pas besoin de
   `supabase_flutter` si aucune authentification n'est requise).
3. `Track` : ajouter `id`, `audioUrl`, `imageUrl`, `duration`, `lyrics`.
4. `Cover` : accepter une URL réseau et utiliser `cached_network_image` pour
   garder les pochettes en cache disque.
5. `PlayerController` : brancher `just_audio` sur l'URL distante.
   - `AudioSource.uri`
   - seek natif via les requêtes `Range` de Supabase Storage
   - état `buffering`, gestion des erreurs réseau et retry
6. Onglet « Téléchargés » : `LockCachingAudioSource` pour conserver localement
   les morceaux déjà écoutés, sans les embarquer dans l'APK.
7. Repli : si Supabase est injoignable, retomber sur les données de démo.

## Points d'attention

- **Poids de l'APK** : aucun MP3 embarqué. Les polices et photos actuelles
  représentent moins de 1 Mo.
- **Trafic sortant** : le streaming consomme le quota Supabase. Prévoir un CDN
  et des formats compressés (AAC/Opus plutôt que WAV).
- **Sécurité** : clé `anon` uniquement, RLS activée, bucket en lecture seule.
- **Hors ligne** : cache progressif, pas de téléchargement massif silencieux.
- **Droits** : ne stocker que des morceaux dont les ayants droit ont autorisé
  la diffusion.

## État

Rien de tout cela n'est encore implémenté. En attendant, l'app utilise
`demoTracks` et un lecteur simulé (`PlayerController`), avec des paroles de
démonstration originales.
