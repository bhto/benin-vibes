import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:benin_vibes/database/app_database.dart';
import 'package:benin_vibes/database/library_repository.dart';

void main() {
  late String seedJson;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    seedJson = File('assets/data/library.json').readAsStringSync();
  });

  Future<AppDatabase> openTestDatabase() {
    return AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      seedJson: seedJson,
    );
  }

  test('le schéma et le seed sont créés', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final db = appDb.database;
    expect(await db.query('genres'), hasLength(6));
    expect(await db.query('artists'), hasLength(9));
    expect(await db.query('tracks'), hasLength(37));

    final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
    expect(foreignKeys.first.values.first, 1);
  });

  test('chaque morceau possède un artiste et un genre', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final orphans = await appDb.database.rawQuery('''
      SELECT t.id
      FROM tracks t
      LEFT JOIN artists a ON a.id = t.artist_id
      LEFT JOIN genres g ON g.id = t.genre_id
      WHERE a.id IS NULL OR g.id IS NULL
    ''');
    expect(orphans, isEmpty);
  });

  test('une clé étrangère invalide est refusée', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final genre = (await appDb.database.query('genres', limit: 1)).first;

    await expectLater(
      appDb.database.insert('tracks', {
        'id': 'morceau_invalide',
        'title': 'Morceau invalide',
        'artist_id': 99999,
        'genre_id': genre['id'],
        'position': 999,
        'duration_seconds': 120,
        'audio_path': 'audio/morceau_invalide.mp3',
        'lyrics_synced': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('un genre en double est refusé', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    await expectLater(
      appDb.database.insert('genres', {
        'slug': 'gospel',
        'name': 'Gospel',
        'color': '#000000',
        'icon': 'church',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('un artiste utilisé ne peut pas être supprimé', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final artist = (await appDb.database.query('artists', limit: 1)).first;

    await expectLater(
      appDb.database.delete(
        'artists',
        where: 'id = ?',
        whereArgs: [artist['id']],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('le repository charge les morceaux et les paroles', () async {
    final library = await MusicRepository.loadFromSeed();

    expect(library.tracks, hasLength(37));

    final agolo = library.tracks.firstWhere(
      (track) => track.id == 'angelique_kidjo_agolo',
    );
    expect(agolo.lyrics, isNotEmpty);
    expect(agolo.lyrics.first.text, contains('Agolo'));
    expect(agolo.lyricsSynced, isTrue);

    final commeAmi = library.tracks.firstWhere(
      (track) => track.id == 'petit_miguelito_comme_ami',
    );
    expect(commeAmi.lyrics, isNotEmpty);
    expect(commeAmi.lyricsSynced, isFalse);
  });

  test('le repository lit la base SQLite locale', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final library = await MusicRepository(appDb).loadLibrary();
    expect(library.tracks, hasLength(37));
    expect(library.artists, hasLength(9));
    expect(library.genres, hasLength(6));

    final agolo = library.tracks.firstWhere(
      (track) => track.id == 'angelique_kidjo_agolo',
    );
    expect(agolo.genre, 'Afropop');
    expect(agolo.artist, 'Angélique Kidjo');
    expect(agolo.image, 'assets/covers/angelique_kidjo.jpg');
    expect(agolo.lyrics, isNotEmpty);
    expect(agolo.liked, isFalse);
    expect(library.featuredTracks, hasLength(5));
    expect(library.newReleases, hasLength(10));
  });

  test('setLiked persiste le favori dans SQLite', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final repo = MusicRepository(appDb);
    await repo.setLiked('angelique_kidjo_agolo', true);

    final library = await repo.loadLibrary();
    final agolo = library.tracks.firstWhere(
      (track) => track.id == 'angelique_kidjo_agolo',
    );
    expect(agolo.liked, isTrue);
    expect(library.tracks.where((track) => track.liked), hasLength(1));

    await repo.setLiked('angelique_kidjo_agolo', false);
    final refreshed = await repo.loadLibrary();
    expect(refreshed.tracks.where((track) => track.liked), isEmpty);
  });

  test('la migration v1 ajoute la colonne liked', () async {
    final directory = await Directory.systemTemp.createTemp('benin_vibes_db');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final path = p.join(directory.path, 'v1.db');

    final legacy = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE tracks (id TEXT PRIMARY KEY)');
        },
      ),
    );
    await legacy.close();

    final appDb = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
      seed: false,
    );
    addTearDown(appDb.close);

    final columns = await appDb.database.rawQuery('PRAGMA table_info(tracks)');
    final liked = columns.firstWhere((column) => column['name'] == 'liked');
    expect(liked['notnull'], 1);
    expect(liked['dflt_value'], '0');
  });

  test('getRandomTracks charge des morceaux au hasard depuis SQLite', () async {
    final appDb = await openTestDatabase();
    addTearDown(appDb.close);

    final repo = MusicRepository(appDb);
    final randomTracks = await repo.getRandomTracks(limit: 6);
    expect(randomTracks, hasLength(6));
    for (final track in randomTracks) {
      expect(track.id, isNotEmpty);
      expect(track.title, isNotEmpty);
      expect(track.artist, isNotEmpty);
    }
  });
}
