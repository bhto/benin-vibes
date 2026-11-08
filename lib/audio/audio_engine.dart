import 'dart:async';

/// Contrat minimal du moteur audio utilisé par [PlayerController].
///
/// L'implémentation réelle s'appuie sur `just_audio` ; les tests et les
/// plateformes sans plugin utilisent la simulation interne du contrôleur.
abstract class AudioEngine {
  /// Position de lecture, mise à jour par le moteur.
  Stream<Duration> get positionStream;

  /// Durée réelle du média, ou `null` tant qu'elle n'est pas connue.
  Stream<Duration?> get durationStream;

  /// Vrai lorsque le moteur joue réellement.
  Stream<bool> get playingStream;

  /// Émis quand le média en cours est arrivé à son terme.
  Stream<void> get completedStream;

  /// Charge une source audio (asset Flutter ou URI) et renvoie la durée détectée.
  Future<Duration?> setSource(String source, {bool isAsset = false});

  /// Charge [url] et renvoie la durée détectée, si disponible.
  Future<Duration?> setUrl(String url);

  /// Démarre la lecture. Le futur se termine à la fin du média.
  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// Règle le volume de lecture, entre 0 et 1.
  Future<void> setVolume(double volume);

  Future<void> stop();

  Future<void> dispose();
}
