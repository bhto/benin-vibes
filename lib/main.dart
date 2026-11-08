import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/audio_source_resolver.dart';
import 'audio/just_audio_engine.dart';
import 'data.dart';
import 'database/library_repository.dart';
import 'home_shell.dart';
import 'onboarding_page.dart';
import 'onboarding_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _clearAudioAssetCache();
  final onboardingStore = FileOnboardingStore();
  final onboardingDone = await onboardingStore.hasCompleted();
  final (repository, library) = await _loadLibrary();
  runApp(
    BeninVibesApp(
      library: library,
      musicRepository: repository,
      audioEngine: JustAudioEngine(),
      audioResolver: AudioSourceResolver(),
      showOnboarding: !onboardingDone,
      onboardingStore: onboardingStore,
    ),
  );
}

/// Supprime les anciennes copies de MP3 extraites par `just_audio`.
///
/// Son cache ne se met pas à jour tout seul quand un asset est remplacé dans
/// l'APK : on le vide donc à chaque lancement pour garantir que la version
/// embarquée est bien celle qui est lue.
Future<void> _clearAudioAssetCache() async {
  try {
    await JustAudioEngine.clearAssetCache();
  } catch (error, stack) {
    debugPrint('Cache audio non nettoyé : $error\n$stack');
  }
}

Future<(MusicRepository?, Library)> _loadLibrary() async {
  try {
    final repository = await MusicRepository.open();
    return (repository, await repository.loadLibrary());
  } catch (error, stack) {
    debugPrint('SQLite indisponible, chargement du seed : $error\n$stack');
    try {
      return (null, await MusicRepository.loadFromSeed());
    } catch (fallbackError, fallbackStack) {
      debugPrint('Seed indisponible : $fallbackError\n$fallbackStack');
      return (null, const Library.empty());
    }
  }
}

class BeninVibesApp extends StatelessWidget {
  final Library library;

  /// Repository SQLite, pour persister les favoris. `null` en test.
  final MusicRepository? musicRepository;

  /// Moteur audio réel. `null` en test : la progression reste simulée.
  final AudioEngine? audioEngine;

  /// Résolution de l'audio local embarqué (`assets/audio/`).
  final AudioSourceResolver? audioResolver;

  /// Faux lorsque l'onboarding a déjà été parcouru : l'accueil s'ouvre
  /// directement au lancement.
  final bool showOnboarding;

  /// Enregistre le passage de l'onboarding pour les lancements suivants.
  final OnboardingStore? onboardingStore;

  const BeninVibesApp({
    super.key,
    required this.library,
    this.musicRepository,
    this.audioEngine,
    this.audioResolver,
    this.showOnboarding = true,
    this.onboardingStore,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benin Vibes',
      theme: buildTheme(),
      home: showOnboarding
          ? OnboardingPage(
              library: library,
              musicRepository: musicRepository,
              audioEngine: audioEngine,
              audioResolver: audioResolver,
              onboardingStore: onboardingStore,
            )
          : HomeShell(
              library: library,
              musicRepository: musicRepository,
              audioEngine: audioEngine,
              audioResolver: audioResolver,
            ),
    );
  }
}
