import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:benin_vibes/audio/audio_source_resolver.dart';
import 'package:benin_vibes/data.dart';
import 'package:benin_vibes/player_controller.dart';

import 'support/fake_audio_engine.dart';
import 'support/library_fixture.dart';

/// Laisse les chargements asynchrones (résolution + setUrl) se terminer.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('La file démarre sur le premier titre de la bibliothèque', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    expect(player.hasSelection, isFalse);
    expect(player.track.title, tracks.first.title);
    expect(player.upNext.length, tracks.length - 1);
  });

  test('rien ne démarre avant le choix d\'un morceau', () {
    final player = PlayerController(tracks: buildTestLibrary().tracks);
    addTearDown(player.dispose);

    player.toggle();
    player.next();
    player.seek(0.5);

    expect(player.hasSelection, isFalse);
    expect(player.playing, isFalse);
  });

  test('playCollection remplace la file et démarre le titre demandé', () {
    final library = buildTestLibrary();
    final player = PlayerController(tracks: library.tracks);
    addTearDown(player.dispose);

    final afropop = library.tracksForGenre('afropop');
    player.playCollection(afropop, startAt: afropop.last);

    expect(player.hasSelection, isTrue);
    expect(player.queue.map((t) => t.id), afropop.map((t) => t.id));
    expect(player.track.id, afropop.last.id);
    expect(player.upNext, isEmpty);

    final gospel = library.tracksForGenre('gospel');
    player.playCollection(gospel);

    expect(player.queue.length, gospel.length);
    expect(player.track.id, gospel.first.id);
  });

  test('playNext place le titre juste après le titre courant', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    final track = tracks[2];
    player.playNext(track);

    expect(player.upNext.first.title, track.title);
    expect(player.upNext.length, tracks.length - 1);
  });

  test('playNext déplace un titre déjà présent sans créer de doublon', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    final track = tracks[1];
    player.playNext(track);

    final matches = player.queue.where((t) => t.id == track.id);
    expect(matches.length, 1);
    expect(player.upNext.first.id, track.id);
  });

  test('addToQueue refuse un titre déjà présent', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    expect(player.addToQueue(tracks[1]), isFalse);
    expect(player.addToQueue(buildTestTrack()), isTrue);
    expect(player.upNext.last.title, 'Inédit');
  });

  test('moveUpNext réordonne les titres à venir', () {
    final player = PlayerController(tracks: buildTestLibrary().tracks);
    addTearDown(player.dispose);

    final before = player.upNext.map((t) => t.title).toList();
    player.moveUpNext(0, 1);
    final after = player.upNext.map((t) => t.title).toList();

    expect(after[0], before[1]);
    expect(after[1], before[0]);
  });

  test('removeUpNext ne retire jamais le titre en cours', () {
    final player = PlayerController(tracks: buildTestLibrary().tracks);
    addTearDown(player.dispose);

    final current = player.track;
    player.removeUpNext(current);
    expect(player.track.title, current.title);

    final next = player.upNext.first;
    player.removeUpNext(next);
    expect(player.upNext.any((t) => t.id == next.id), isFalse);
  });

  test('toggleShuffle mélange les titres à venir et restaure l\'ordre', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    final before = player.queue.map((t) => t.id).toList();
    player.toggleShuffle();

    expect(player.shuffle, isTrue);
    expect(player.track.id, before.first);
    expect(player.queue.map((t) => t.id).toSet(), before.toSet());
    expect(player.upNext, hasLength(tracks.length - 1));

    player.toggleShuffle();
    expect(player.shuffle, isFalse);
    expect(player.queue.map((t) => t.id), before);
    expect(player.track.id, before.first);
  });

  test('le cœur ajoute et retire un favori sans base de données', () async {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    expect(player.isLiked(tracks.first), isFalse);
    expect(player.favorites, isEmpty);

    await player.toggleLike();
    expect(player.isLiked(tracks.first), isTrue);
    expect(player.favorites.single.id, tracks.first.id);

    await player.toggleLike();
    expect(player.isLiked(tracks.first), isFalse);
    expect(player.favorites, isEmpty);
  });

  test('la répétition relance la file après le dernier titre', () async {
    final tracks = buildTestLibrary().tracks;
    final engine = FakeAudioEngine()..nextDuration = const Duration(minutes: 3);
    final player = PlayerController(tracks: tracks, engine: engine);
    addTearDown(player.dispose);

    player.playCollection(tracks, startAt: tracks.last);
    await settle();
    expect(player.repeat, isFalse);

    engine.complete();
    await settle();
    expect(player.playing, isFalse);
    expect(player.track.id, tracks.last.id);

    player.toggleRepeat();
    expect(player.repeat, isTrue);
    player.playCollection(tracks, startAt: tracks.last);
    await settle();

    engine.complete();
    await settle();
    expect(player.playing, isTrue);
    expect(player.track.id, tracks.first.id);
  });

  test('la durée suit le morceau en cours', () {
    final tracks = buildTestLibrary().tracks;
    final player = PlayerController(tracks: tracks);
    addTearDown(player.dispose);

    player.play(tracks.first);
    expect(player.hasSelection, isTrue);
    expect(player.duration, tracks.first.duration);
    player.next();
    expect(player.duration, tracks[1].duration);
  });

  group('moteur audio réel', () {
    late Directory storage;
    late FakeAudioEngine engine;

    setUp(() async {
      storage = await Directory.systemTemp.createTemp('benin_vibes_audio');
      final audio = Directory(p.join(storage.path, 'audio'))
        ..createSync(recursive: true);
      File(p.join(audio.path, 'zinli_night.mp3'))
          .writeAsBytesSync(const [0, 1, 2]);
      File(p.join(audio.path, 'cotonou_vibes.mp3'))
          .writeAsBytesSync(const [0, 1, 2]);
      engine = FakeAudioEngine()..nextDuration = const Duration(minutes: 4);
    });

    tearDown(() async {
      if (await storage.exists()) await storage.delete(recursive: true);
    });

    PlayerController buildPlayer() {
      return PlayerController(
        tracks: buildTestLibrary().tracks,
        engine: engine,
        resolver: AudioSourceResolver(externalDirectory: () async => storage),
      );
    }

    test('lit le MP3 local et expose la durée du moteur', () async {
      final player = buildPlayer();
      addTearDown(player.dispose);

      player.play(player.queue.first);
      await settle();

      expect(Uri.parse(engine.lastUrl!).scheme, 'file');
      expect(engine.lastUrl, endsWith('zinli_night.mp3'));
      expect(engine.isPlaying, isTrue);
      expect(player.duration, const Duration(minutes: 4));
      expect(player.playing, isTrue);
    });

    test('la position et la progression viennent du moteur', () async {
      final player = buildPlayer();
      addTearDown(player.dispose);

      player.play(player.queue.first);
      await settle();

      engine.emitPosition(const Duration(seconds: 60));
      await settle();

      expect(player.position, const Duration(seconds: 60));
      expect(player.progress, closeTo(0.25, 0.001));
    });

    test('toggle met le moteur en pause puis reprend', () async {
      final player = buildPlayer();
      addTearDown(player.dispose);

      player.play(player.queue.first);
      await settle();

      player.toggle();
      await settle();
      expect(engine.isPlaying, isFalse);
      expect(player.playing, isFalse);

      player.toggle();
      await settle();
      expect(engine.isPlaying, isTrue);
      expect(player.playing, isTrue);
    });

    test('seek positionne le moteur sur la durée réelle', () async {
      final player = buildPlayer();
      addTearDown(player.dispose);

      player.play(player.queue.first);
      await settle();

      player.seek(0.5);
      await settle();

      expect(engine.lastSeek, const Duration(minutes: 2));
    });

    test('la fin du morceau enchaîne sur le suivant', () async {
      final tracks = buildTestLibrary().tracks;
      final player = buildPlayer();
      addTearDown(player.dispose);

      player.play(tracks.first);
      await settle();

      engine.complete();
      await settle();

      expect(player.track.id, tracks[1].id);
      expect(engine.lastUrl, endsWith('cotonou_vibes.mp3'));
    });

    test('le volume est appliqué au moteur et conservé', () async {
      final player = buildPlayer();
      addTearDown(player.dispose);

      expect(player.volume, 0.65);
      expect(engine.volume, 0.65);

      player.setVolume(0.3);
      await settle();

      expect(player.volume, 0.3);
      expect(engine.volume, 0.3);

      player.setVolume(1.4);
      await settle();
      expect(player.volume, 1);
      expect(engine.volume, 1);

      player.play(player.queue.first);
      await settle();
      expect(engine.volume, 1);
    });

    test('sans fichier externe, utilise l\'asset embarqué', () async {
      final player = PlayerController(
        tracks: buildTestLibrary().tracks,
        engine: engine,
        resolver: AudioSourceResolver(externalDirectory: () async => null),
      );
      addTearDown(player.dispose);

      player.play(player.queue.first);
      await settle();

      expect(engine.lastSource, 'assets/audio/zinli_night.mp3');
      expect(engine.lastIsAsset, isTrue);
      expect(engine.isPlaying, isTrue);
      expect(player.playing, isTrue);
    });

    test('sans fichier ni URL, la progression est simulée', () async {
      const track = Track(
        id: 'sans_audio',
        title: 'Sans audio',
        artist: 'Artiste test',
        artistSlug: 'artiste_test',
        genre: 'Afropop',
        genreSlug: 'afropop',
        audioPath: '',
        duration: Duration(minutes: 3),
      );
      final player = PlayerController(
        tracks: const [track],
        engine: engine,
        resolver: AudioSourceResolver(externalDirectory: () async => null),
      );
      addTearDown(player.dispose);

      player.play(track);
      await settle();

      expect(engine.lastUrl, isNull);
      expect(engine.stopped, isTrue);
      expect(player.playing, isTrue);
    });
  });
}
