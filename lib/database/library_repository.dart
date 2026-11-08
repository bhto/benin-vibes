import 'dart:convert';

import 'package:flutter/services.dart';

import '../data.dart';
import 'app_database.dart';
import 'library_seed.dart';

/// Charge la bibliothèque depuis SQLite (ou depuis le seed embarqué sur les
/// plateformes où le plugin SQLite n'est pas disponible, comme le bureau).
class MusicRepository {
  final AppDatabase database;

  const MusicRepository(this.database);

  static Future<MusicRepository> open() async {
    return MusicRepository(await AppDatabase.open());
  }

  /// Lit les artistes, genres et morceaux de la base SQLite locale, puis charge les
  /// paroles depuis les assets. « À la une » et « Nouveautés » sont sélectionnés
  /// au hasard directement dans la base SQLite via ORDER BY RANDOM().
  Future<Library> loadLibrary({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;

    final genreRows = await database.database.query('genres', orderBy: 'name');
    final artistRows = await database.database.query(
      'artists',
      orderBy: 'name',
    );
    final trackRows = await database.database.rawQuery('''
      SELECT t.*, a.name AS artist_name, a.slug AS artist_slug,
             a.tint AS artist_tint
      FROM tracks t
      JOIN artists a ON a.id = t.artist_id
      ORDER BY t.position, t.title
    ''');

    final genres = <Genre>[
      for (final row in genreRows)
        Genre(
          id: row['id'] as int,
          slug: row['slug'] as String,
          name: row['name'] as String,
          color: colorFromHex(row['color'] as String?),
          icon: genreIcon(row['icon'] as String? ?? ''),
        ),
    ];

    final artists = <Artist>[
      for (final row in artistRows)
        Artist(
          id: row['id'] as int,
          slug: row['slug'] as String,
          name: row['name'] as String,
          image: row['cover_path'] as String?,
          tint: colorFromHex(row['tint'] as String?),
        ),
    ];

    final genresById = {for (final genre in genres) genre.id: genre};
    final artistsById = {for (final artist in artists) artist.id: artist};

    final tracks = <Track>[];
    for (final row in trackRows) {
      final artist = artistsById[row['artist_id'] as int];
      final genre = genresById[row['genre_id'] as int];
      if (artist == null || genre == null) {
        throw StateError('Morceau orphelin : ${row['id']}');
      }

      final lyricsPath = row['lyrics_path'] as String?;
      final lyrics = await _loadLyrics(assets, lyricsPath);

      tracks.add(
        Track(
          id: row['id'] as String,
          title: row['title'] as String,
          artist: artist.name,
          artistSlug: artist.slug,
          genre: genre.name,
          genreSlug: genre.slug,
          image: (row['cover_path'] as String?) ?? artist.image,
          tint: artist.tint,
          lyrics: lyrics,
          lyricsSynced: (row['lyrics_synced'] as int? ?? 0) == 1,
          liked: (row['liked'] as int? ?? 0) == 1,
          audioPath: row['audio_path'] as String,
          duration: Duration(seconds: row['duration_seconds'] as int? ?? 0),
        ),
      );
    }

    final tracksById = {for (final track in tracks) track.id: track};

    // Sélection aléatoire directement depuis SQLite (ORDER BY RANDOM())
    final featuredRows = await database.database.rawQuery('''
      SELECT id FROM tracks ORDER BY RANDOM() LIMIT 5
    ''');
    final newReleaseRows = await database.database.rawQuery('''
      SELECT id FROM tracks ORDER BY RANDOM() LIMIT 10
    ''');

    final featuredTracks = [
      for (final row in featuredRows)
        if (tracksById[row['id']] != null) tracksById[row['id']]!,
    ];
    final newReleases = [
      for (final row in newReleaseRows)
        if (tracksById[row['id']] != null) tracksById[row['id']]!,
    ];

    return Library(
      artists: artists,
      genres: genres,
      tracks: tracks,
      featuredTracks: featuredTracks,
      newReleases: newReleases,
    );
  }

  /// Enregistre l'état « favori » d'un morceau dans SQLite.
  Future<void> setLiked(String trackId, bool liked) async {
    await database.database.update(
      'tracks',
      {'liked': liked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  /// Charge [limit] morceaux tirés au sort dans SQLite avec ORDER BY RANDOM().
  Future<List<Track>> getRandomTracks({
    int limit = 10,
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final rows = await database.database.rawQuery(
      '''
      SELECT t.*, a.name AS artist_name, a.slug AS artist_slug,
             a.tint AS artist_tint, a.cover_path AS artist_cover,
             g.name AS genre_name, g.slug AS genre_slug
      FROM tracks t
      JOIN artists a ON a.id = t.artist_id
      JOIN genres g ON g.id = t.genre_id
      ORDER BY RANDOM()
      LIMIT ?
    ''',
      [limit],
    );

    final results = <Track>[];
    for (final row in rows) {
      final lyrics = await _loadLyrics(assets, row['lyrics_path'] as String?);
      results.add(
        Track(
          id: row['id'] as String,
          title: row['title'] as String,
          artist: row['artist_name'] as String,
          artistSlug: row['artist_slug'] as String,
          genre: row['genre_name'] as String,
          genreSlug: row['genre_slug'] as String,
          image:
              (row['cover_path'] as String?) ??
              (row['artist_cover'] as String?),
          tint: colorFromHex(row['artist_tint'] as String?),
          lyrics: lyrics,
          lyricsSynced: (row['lyrics_synced'] as int? ?? 0) == 1,
          liked: (row['liked'] as int? ?? 0) == 1,
          audioPath: row['audio_path'] as String,
          duration: Duration(seconds: row['duration_seconds'] as int? ?? 0),
        ),
      );
    }
    return results;
  }

  /// Repli sans SQLite : lit directement le seed et les assets.
  static Future<Library> loadFromSeed({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final seed = LibrarySeed.decode(await assets.loadString(kLibrarySeedAsset));

    final genres = <Genre>[
      for (var i = 0; i < seed.genres.length; i++)
        Genre(
          id: i + 1,
          slug: seed.genres[i].slug,
          name: seed.genres[i].name,
          color: colorFromHex(seed.genres[i].color),
          icon: genreIcon(seed.genres[i].icon),
        ),
    ];

    final artists = <Artist>[
      for (var i = 0; i < seed.artists.length; i++)
        Artist(
          id: i + 1,
          slug: seed.artists[i].slug,
          name: seed.artists[i].name,
          image: seed.artists[i].coverPath,
          tint: colorFromHex(seed.artists[i].tint),
        ),
    ];

    final artistsBySlug = {for (final artist in artists) artist.slug: artist};
    final genresBySlug = {for (final genre in genres) genre.slug: genre};

    final ordered = [...seed.tracks]
      ..sort((a, b) => a.position.compareTo(b.position));

    final tracks = <Track>[];
    for (final seedTrack in ordered) {
      final artist = artistsBySlug[seedTrack.artistSlug];
      final genre = genresBySlug[seedTrack.genreSlug];
      if (artist == null || genre == null) {
        throw FormatException('Références invalides pour ${seedTrack.id}.');
      }

      tracks.add(
        Track(
          id: seedTrack.id,
          title: seedTrack.title,
          artist: artist.name,
          artistSlug: artist.slug,
          genre: genre.name,
          genreSlug: genre.slug,
          image: seedTrack.coverPath ?? artist.image,
          tint: artist.tint,
          lyrics: await _loadLyrics(assets, seedTrack.lyricsPath),
          lyricsSynced: seedTrack.lyricsSynced,
          audioPath: seedTrack.audioPath,
          duration: Duration(seconds: seedTrack.durationSeconds),
        ),
      );
    }

    final featuredTracks = (List<Track>.of(tracks)..shuffle()).take(5).toList();
    final newReleases = (List<Track>.of(tracks)..shuffle()).take(10).toList();

    return Library(
      artists: artists,
      genres: genres,
      tracks: tracks,
      featuredTracks: featuredTracks,
      newReleases: newReleases,
    );
  }

  static Future<List<LyricLine>> _loadLyrics(
    AssetBundle assets,
    String? path,
  ) async {
    if (path == null || path.isEmpty) return const [];
    return parseLyricLines(await assets.loadString(path));
  }
}

/// Convertit le JSON `[{ "t": 1920, "text": "..." }]` en lignes horodatées.
List<LyricLine> parseLyricLines(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) return const [];

  final lines = <LyricLine>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final time = item['t'];
    final text = item['text'];
    if (time is num && text is String && text.trim().isNotEmpty) {
      lines.add(LyricLine(Duration(milliseconds: time.toInt()), text));
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}
