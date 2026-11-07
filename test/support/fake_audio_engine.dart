import 'dart:async';

import 'package:benin_vibes/audio/audio_engine.dart';

/// Moteur audio factice pour les tests : aucun plugin natif requis.
class FakeAudioEngine implements AudioEngine {
  final _positions = StreamController<Duration>.broadcast();
  final _durations = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();

  String? lastUrl;
  String? lastSource;
  bool? lastIsAsset;
  Duration? nextDuration;
  Duration? lastSeek;
  bool isPlaying = false;
  bool stopped = false;
  bool disposed = false;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Stream<Duration?> get durationStream => _durations.stream;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Future<Duration?> setSource(String source, {bool isAsset = false}) async {
    lastSource = source;
    lastIsAsset = isAsset;
    lastUrl = source;
    return nextDuration;
  }

  @override
  Future<Duration?> setUrl(String url) => setSource(url);

  @override
  Future<void> play() async {
    isPlaying = true;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    _positions.add(position);
  }

  @override
  Future<void> stop() async {
    stopped = true;
    isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positions.close();
    await _durations.close();
    await _playing.close();
    await _completed.close();
  }

  /// Simule une position émise par le moteur.
  void emitPosition(Duration position) => _positions.add(position);

  /// Simule la découverte de la durée réelle.
  void emitDuration(Duration duration) => _durations.add(duration);

  /// Simule la fin du morceau.
  void complete() => _completed.add(null);
}
