import 'package:just_audio/just_audio.dart';

import 'audio_engine.dart';

/// Moteur audio basé sur `just_audio`.
///
/// Il gère les assets locaux Flutter (`assets/audio/...`), les fichiers
/// locaux (`file://...`) et les URL distantes.
class JustAudioEngine implements AudioEngine {
  final AudioPlayer _player;

  JustAudioEngine({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// Vide le cache d'assets extraits par `just_audio`.
  ///
  /// `just_audio` copie chaque asset dans un fichier temporaire et ne le
  /// remplace jamais, même après une mise à jour de l'APK : sans ce nettoyage,
  /// un ancien MP3 continue d'être lu. À appeler au démarrage, avant toute
  /// lecture.
  static Future<void> clearAssetCache() => AudioPlayer.clearAssetCache();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<bool> get playingStream =>
      _player.playerStateStream.map((state) => state.playing).distinct();

  @override
  Stream<void> get completedStream => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<Duration?> setSource(String source, {bool isAsset = false}) {
    if (isAsset || source.startsWith('assets/')) {
      return _player.setAsset(source);
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return _player.setUrl(source);
    }
    if (source.startsWith('file://')) {
      return _player.setFilePath(Uri.parse(source).toFilePath());
    }
    return _player.setFilePath(source);
  }

  @override
  Future<Duration?> setUrl(String url) => setSource(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
