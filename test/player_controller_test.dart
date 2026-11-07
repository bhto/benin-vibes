import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/data.dart';
import 'package:benin_vibes/player_controller.dart';

void main() {
  test('La file démarre sur le premier titre de démonstration', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    expect(player.track.title, demoTracks.first.title);
    expect(player.upNext.length, demoTracks.length - 1);
  });

  test('playNext place le titre juste après le titre courant', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    final track = demoTracks[3];
    player.playNext(track);

    expect(player.upNext.first.title, track.title);
    expect(player.upNext.length, demoTracks.length - 1);
  });

  test('playNext déplace un titre déjà présent sans créer de doublon', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    final track = demoTracks[4];
    player.playNext(track);

    final matches = player.queue.where((t) => t.title == track.title);
    expect(matches.length, 1);
    expect(player.upNext.first.title, track.title);
  });

  test('addToQueue refuse un titre déjà présent', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    expect(player.addToQueue(demoTracks[1]), isFalse);
    expect(player.addToQueue(const Track('Inédit', 'Artiste test')), isTrue);
    expect(player.upNext.last.title, 'Inédit');
  });

  test('moveUpNext réordonne les titres à venir', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    final before = player.upNext.map((t) => t.title).toList();
    player.moveUpNext(0, 2);
    final after = player.upNext.map((t) => t.title).toList();

    expect(after[0], before[1]);
    expect(after[2], before[0]);
  });

  test('removeUpNext ne retire jamais le titre en cours', () {
    final player = PlayerController();
    addTearDown(player.dispose);

    final current = player.track;
    player.removeUpNext(current);
    expect(player.track.title, current.title);

    final next = player.upNext.first;
    player.removeUpNext(next);
    expect(player.upNext.any((t) => t.title == next.title), isFalse);
  });
}
