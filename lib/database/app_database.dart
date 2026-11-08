import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'library_seed.dart';

/// Nom du seed embarqué, utilisé au premier lancement.
const String kLibrarySeedAsset = 'assets/data/library.json';

/// Base SQLite locale de la bibliothèque.
///
/// Schéma (version 2) :
/// - `genres` : table de référence des types musicaux ;
/// - `artists` : artistes séparés des morceaux ;
/// - `tracks` : morceaux, avec clés étrangères vers `artists` et `genres` et
///   la colonne `liked` pour les favoris.
///
/// Les contraintes `ON DELETE RESTRICT` empêchent de supprimer un artiste ou
/// un genre encore utilisé. `PRAGMA foreign_keys = ON` est activé à chaque
/// ouverture.
class AppDatabase {
  /// Version courante du schéma. La 2 ajoute `tracks.liked`.
  static const int schemaVersion = 2;

  final Database database;

  AppDatabase._(this.database);

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    String? seedJson,
    bool seed = true,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await getDatabasesPath(), 'benin_vibes.db');

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          if (seed) {
            final raw =
                seedJson ?? await rootBundle.loadString(kLibrarySeedAsset);
            await _seed(db, LibrarySeed.decode(raw));
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE tracks ADD COLUMN liked INTEGER NOT NULL '
              'DEFAULT 0 CHECK (liked IN (0, 1))',
            );
          }
        },
      ),
    );

    return AppDatabase._(db);
  }

  Future<void> close() => database.close();

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE genres (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        slug  TEXT NOT NULL UNIQUE,
        name  TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        icon  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE artists (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        slug       TEXT NOT NULL UNIQUE,
        name       TEXT NOT NULL UNIQUE,
        cover_path TEXT,
        tint       TEXT NOT NULL
      )
    ''');

    await db.execute('''
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
      )
    ''');

    await db.execute('CREATE INDEX idx_tracks_artist ON tracks (artist_id)');
    await db.execute('CREATE INDEX idx_tracks_genre ON tracks (genre_id)');
    await db.execute('CREATE INDEX idx_tracks_position ON tracks (position)');
  }

  static Future<void> _seed(Database db, LibrarySeed seed) async {
    final genreIds = <String, int>{};
    for (final genre in seed.genres) {
      genreIds[genre.slug] = await db.insert('genres', {
        'slug': genre.slug,
        'name': genre.name,
        'color': genre.color,
        'icon': genre.icon,
      });
    }

    final artistIds = <String, int>{};
    for (final artist in seed.artists) {
      artistIds[artist.slug] = await db.insert('artists', {
        'slug': artist.slug,
        'name': artist.name,
        'cover_path': artist.coverPath,
        'tint': artist.tint,
      });
    }

    for (final track in seed.tracks) {
      final artistId = artistIds[track.artistSlug];
      final genreId = genreIds[track.genreSlug];
      if (artistId == null || genreId == null) {
        throw FormatException('Références invalides pour ${track.id}.');
      }
      await db.insert('tracks', {
        'id': track.id,
        'title': track.title,
        'artist_id': artistId,
        'genre_id': genreId,
        'position': track.position,
        'duration_seconds': track.durationSeconds,
        'audio_path': track.audioPath,
        'cover_path': track.coverPath,
        'lyrics_path': track.lyricsPath,
        'lyrics_synced': track.lyricsSynced ? 1 : 0,
      });
    }
  }
}
