import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/database/library_seed.dart';

void main() {
  late LibrarySeed seed;

  setUpAll(() {
    seed = LibrarySeed.decode(
      File('assets/data/library.json').readAsStringSync(),
    );
  });

  test('le seed contient toute la bibliothèque', () {
    expect(seed.tracks, hasLength(37));
    expect(seed.artists, hasLength(9));
    expect(seed.genres, hasLength(6));
  });

  test('chaque morceau référence un artiste et un genre existants', () {
    final artistSlugs = {for (final artist in seed.artists) artist.slug};
    final genreSlugs = {for (final genre in seed.genres) genre.slug};

    for (final track in seed.tracks) {
      expect(artistSlugs, contains(track.artistSlug), reason: track.id);
      expect(genreSlugs, contains(track.genreSlug), reason: track.id);
    }
  });

  test('les identifiants et les positions sont uniques', () {
    final ids = seed.tracks.map((track) => track.id).toList();
    final positions = seed.tracks.map((track) => track.position).toList();

    expect(ids.toSet(), hasLength(ids.length));
    expect(positions.toSet(), hasLength(positions.length));
  });

  test('les pochettes et les paroles embarquées existent', () {
    for (final artist in seed.artists) {
      final cover = artist.coverPath;
      if (cover == null) continue;
      expect(File(cover).existsSync(), isTrue, reason: cover);
    }

    for (final track in seed.tracks) {
      final cover = track.coverPath;
      if (cover != null) {
        expect(File(cover).existsSync(), isTrue, reason: cover);
      }

      final lyricsPath = track.lyricsPath;
      if (lyricsPath == null) continue;

      final file = File(lyricsPath);
      expect(file.existsSync(), isTrue, reason: lyricsPath);

      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<List<dynamic>>(), reason: lyricsPath);
      final lines = decoded as List<dynamic>;
      expect(lines, isNotEmpty, reason: lyricsPath);

      var previous = -1;
      for (final line in lines) {
        final lineMap = line as Map<String, dynamic>;
        final time = lineMap['t'] as int;
        final text = lineMap['text'] as String;
        expect(time, greaterThanOrEqualTo(previous), reason: lyricsPath);
        expect(text.trim(), isNotEmpty, reason: lyricsPath);
        previous = time;
      }
    }
  });

  test('les cinq morceaux avec paroles sont marqués correctement', () {
    final withLyrics = seed.tracks.where((track) => track.lyricsPath != null);
    expect(withLyrics, hasLength(5));
    expect(withLyrics.where((track) => track.lyricsSynced), hasLength(4));

    final commeAmi = seed.tracks.firstWhere(
      (track) => track.id == 'petit_miguelito_comme_ami',
    );
    expect(commeAmi.lyricsPath, isNotNull);
    expect(commeAmi.lyricsSynced, isFalse);
  });
}
