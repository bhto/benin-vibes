import 'dart:convert';

/// Le seed embarqué décrit la bibliothèque avant son insertion dans SQLite.
///
/// Structure attendue :
///
/// ```json
/// {
///   "genres":  [ { "slug": "...", "name": "...", "color": "#...", "icon": "..." } ],
///   "artists": [ { "slug": "...", "name": "...", "cover_path": "...", "tint": "#..." } ],
///   "tracks":  [ { "id": "...", "title": "...", "artist": "...", "genre": "...",
///                  "duration_seconds": 261, "audio_path": "...",
///                  "cover_path": "...", "lyrics_path": "...",
///                  "lyrics_synced": true, "position": 0 } ]
/// }
/// ```
class LibrarySeed {
  final List<SeedGenre> genres;
  final List<SeedArtist> artists;
  final List<SeedTrack> tracks;

  const LibrarySeed({
    required this.genres,
    required this.artists,
    required this.tracks,
  });

  factory LibrarySeed.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Le seed doit être un objet JSON.');
    }

    final genres = _list(decoded, 'genres')
        .map((item) => SeedGenre.fromJson(_object(item, 'genres')))
        .toList(growable: false);
    final artists = _list(decoded, 'artists')
        .map((item) => SeedArtist.fromJson(_object(item, 'artists')))
        .toList(growable: false);
    final tracks = _list(decoded, 'tracks')
        .map((item) => SeedTrack.fromJson(_object(item, 'tracks')))
        .toList(growable: false);

    final seed = LibrarySeed(genres: genres, artists: artists, tracks: tracks);
    seed.validate();
    return seed;
  }

  void validate() {
    if (genres.isEmpty) {
      throw const FormatException('Le seed ne contient aucun genre.');
    }
    if (artists.isEmpty) {
      throw const FormatException('Le seed ne contient aucun artiste.');
    }
    if (tracks.isEmpty) {
      throw const FormatException('Le seed ne contient aucun morceau.');
    }

    final genreSlugs = <String>{};
    for (final genre in genres) {
      if (!genreSlugs.add(genre.slug)) {
        throw FormatException('Genre en double : ${genre.slug}');
      }
    }

    final artistSlugs = <String>{};
    for (final artist in artists) {
      if (!artistSlugs.add(artist.slug)) {
        throw FormatException('Artiste en double : ${artist.slug}');
      }
    }

    final trackIds = <String>{};
    final positions = <int>{};
    for (final track in tracks) {
      if (!trackIds.add(track.id)) {
        throw FormatException('Morceau en double : ${track.id}');
      }
      if (!positions.add(track.position)) {
        throw FormatException('Position en double : ${track.position}');
      }
      if (!artistSlugs.contains(track.artistSlug)) {
        throw FormatException(
          'Artiste inconnu pour ${track.id} : ${track.artistSlug}',
        );
      }
      if (!genreSlugs.contains(track.genreSlug)) {
        throw FormatException(
          'Genre inconnu pour ${track.id} : ${track.genreSlug}',
        );
      }
      if (track.durationSeconds <= 0) {
        throw FormatException('Durée invalide pour ${track.id}.');
      }
    }
  }

  static List<dynamic> _list(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is! List) {
      throw FormatException('« $key » doit être une liste.');
    }
    return value;
  }

  static Map<String, dynamic> _object(dynamic value, String key) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Chaque entrée de « $key » doit être un objet.');
    }
    return value;
  }

  static String _string(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('« $key » manquant ou invalide.');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('« $key » doit être une chaîne.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _int(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('« $key » doit être un entier.');
  }
}

class SeedGenre {
  final String slug;
  final String name;
  final String color;
  final String icon;

  const SeedGenre({
    required this.slug,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory SeedGenre.fromJson(Map<String, dynamic> json) => SeedGenre(
    slug: LibrarySeed._string(json, 'slug'),
    name: LibrarySeed._string(json, 'name'),
    color: LibrarySeed._string(json, 'color'),
    icon: LibrarySeed._string(json, 'icon'),
  );
}

class SeedArtist {
  final String slug;
  final String name;
  final String? coverPath;
  final String tint;

  const SeedArtist({
    required this.slug,
    required this.name,
    required this.tint,
    this.coverPath,
  });

  factory SeedArtist.fromJson(Map<String, dynamic> json) => SeedArtist(
    slug: LibrarySeed._string(json, 'slug'),
    name: LibrarySeed._string(json, 'name'),
    coverPath: LibrarySeed._optionalString(json, 'cover_path'),
    tint: LibrarySeed._string(json, 'tint'),
  );
}

class SeedTrack {
  final String id;
  final String title;
  final String artistSlug;
  final String genreSlug;
  final int durationSeconds;
  final String audioPath;
  final String? coverPath;
  final String? lyricsPath;
  final bool lyricsSynced;
  final int position;

  const SeedTrack({
    required this.id,
    required this.title,
    required this.artistSlug,
    required this.genreSlug,
    required this.durationSeconds,
    required this.audioPath,
    required this.position,
    this.coverPath,
    this.lyricsPath,
    this.lyricsSynced = false,
  });

  factory SeedTrack.fromJson(Map<String, dynamic> json) {
    final lyricsPath = LibrarySeed._optionalString(json, 'lyrics_path');
    return SeedTrack(
      id: LibrarySeed._string(json, 'id'),
      title: LibrarySeed._string(json, 'title'),
      artistSlug: LibrarySeed._string(json, 'artist'),
      genreSlug: LibrarySeed._string(json, 'genre'),
      durationSeconds: LibrarySeed._int(json, 'duration_seconds'),
      audioPath: LibrarySeed._string(json, 'audio_path'),
      coverPath: LibrarySeed._optionalString(json, 'cover_path'),
      lyricsPath: lyricsPath,
      lyricsSynced: lyricsPath != null && json['lyrics_synced'] == true,
      position: LibrarySeed._int(json, 'position'),
    );
  }
}
