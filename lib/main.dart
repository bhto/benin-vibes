import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/audio_source_resolver.dart';
import 'audio/just_audio_engine.dart';
import 'data.dart';
import 'database/library_repository.dart';
import 'onboarding_page.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = await _loadLibrary();
  runApp(
    BeninVibesApp(
      library: library,
      audioEngine: JustAudioEngine(),
      audioResolver: AudioSourceResolver(),
    ),
  );
}

Future<Library> _loadLibrary() async {
  try {
    final repository = await MusicRepository.open();
    return await repository.loadLibrary();
  } catch (error, stack) {
    debugPrint('SQLite indisponible, chargement du seed : $error\n$stack');
    try {
      return await MusicRepository.loadFromSeed();
    } catch (fallbackError, fallbackStack) {
      debugPrint('Seed indisponible : $fallbackError\n$fallbackStack');
      return const Library.empty();
    }
  }
}

class BeninVibesApp extends StatelessWidget {
  final Library library;

  /// Moteur audio réel. `null` en test : la progression reste simulée.
  final AudioEngine? audioEngine;

  /// Résolution de l'audio local embarqué (`assets/audio/`).
  final AudioSourceResolver? audioResolver;

  const BeninVibesApp({
    super.key,
    required this.library,
    this.audioEngine,
    this.audioResolver,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benin Vibes',
      theme: buildTheme(),
      home: OnboardingPage(
        library: library,
        audioEngine: audioEngine,
        audioResolver: audioResolver,
      ),
    );
  }
}
