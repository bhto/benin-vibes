import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/audio/source_switch_queue.dart';

void main() {
  test('ignore une demande remplacée avant son démarrage', () async {
    final queue = SourceSwitchQueue();
    final started = <int>[];

    final first = queue.run(() async {
      started.add(1);
      return 1;
    });
    final second = queue.run(() async {
      started.add(2);
      return 2;
    });

    expect(await first, isNull);
    expect(await second, 2);
    expect(started, [2]);
  });

  test('exécute les chargements dans l\'ordre et garde le dernier', () async {
    final queue = SourceSwitchQueue();
    final gate = Completer<void>();
    final applied = <int>[];

    final first = queue.run(() async {
      applied.add(1);
      await gate.future;
      return 1;
    });
    await Future<void>.delayed(Duration.zero);

    final second = queue.run(() async {
      applied.add(2);
      return 2;
    });
    expect(applied, [1]);

    gate.complete();
    expect(await first, 1);
    expect(await second, 2);
    expect(applied, [1, 2]);
  });

  test('une erreur ne bloque pas la demande suivante', () async {
    final queue = SourceSwitchQueue();

    final first = queue.run<Duration>(
      () async => throw StateError('source illisible'),
    );
    final firstExpectation = expectLater(first, throwsStateError);
    await Future<void>.delayed(Duration.zero);

    final second = queue.run<Duration>(() async => const Duration(seconds: 1));

    await firstExpectation;
    expect(await second, const Duration(seconds: 1));
  });
}
