import 'dart:io';

import 'package:benin_vibes/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le marqueur est absent puis présent après le passage', () async {
    final directory = await Directory.systemTemp.createTemp('benin_onboarding');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final store = FileOnboardingStore(directory: () async => directory);
    expect(await store.hasCompleted(), isFalse);

    await store.markCompleted();
    expect(await store.hasCompleted(), isTrue);

    // Nouveau lancement : un store neuf lit le même marqueur.
    final nextLaunch = FileOnboardingStore(directory: () async => directory);
    expect(await nextLaunch.hasCompleted(), isTrue);
  });

  test('un dossier inaccessible ne bloque pas l\'application', () async {
    final store = FileOnboardingStore(
      directory: () async => throw const FileSystemException('refusé'),
    );

    expect(await store.hasCompleted(), isFalse);
    await store.markCompleted();
  });
}
