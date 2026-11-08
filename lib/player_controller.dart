import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio/audio_engine.dart';
import 'audio/audio_source_resolver.dart';
import 'data.dart';

/// État de lecture partagé entre le mini-lecteur, la vue plein écran, les
/// paroles et la file d'attente.
///
/// Quand un [AudioEngine] est fourni, la position et la durée viennent du
/// moteur réel (`just_audio`). Sans moteur — ou si aucun fichier audio n'est
/// disponible — la progression est simulée pour que l'interface reste
/// utilisable.
class PlayerController extends ChangeNotifier {
  final List<Track> _queue;
  final AudioEngine? _engine;
  final AudioSourceResolver? _resolver;

  int _index = 0;
  bool _playing = false;
  bool _selected = false;

  /// Vrai lorsqu'un morceau a déjà été choisi par l'utilisateur.
  ///
  /// Tant que c'est faux, aucun mini-lecteur n'est affiché et aucun son ne
  /// démarre : l'application attend un choix explicite.
  bool get hasSelection => _selected && _queue.isNotEmpty;

  /// Vrai lorsque la progression est simulée (pas de moteur ou pas de source).
  bool _simulated = true;
  double _simulatedProgress = 0;

  Duration _position = Duration.zero;
  Duration? _engineDuration;

  /// Incrémenté à chaque chargement pour ignorer les réponses obsolètes.
  int _loadToken = 0;

  Timer? _ticker;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<void>? _completedSub;

  PlayerController({
    required List<Track> tracks,
    AudioEngine? engine,
    AudioSourceResolver? resolver,
  }) : _queue = List<Track>.of(tracks),
       _engine = engine,
       _resolver = engine == null ? null : (resolver ?? AudioSourceResolver()) {
    _bindEngine();
  }

  Track get track => _queue[_index];
  bool get playing => _playing;

  bool get isEmpty => _queue.isEmpty;

  Duration get duration {
    if (_queue.isEmpty) return Duration.zero;
    if (_simulated) return track.duration;
    return _engineDuration ?? track.duration;
  }

  Duration get position {
    if (_simulated) return duration * _simulatedProgress;
    final total = duration;
    return _position > total ? total : _position;
  }

  double get progress {
    if (_simulated) return _simulatedProgress.clamp(0.0, 1.0);
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Toute la file, dans l'ordre de lecture.
  List<Track> get queue => List.unmodifiable(_queue);

  /// Index du titre en cours dans [queue].
  int get index => _index;

  /// Les titres qui seront lus après le morceau en cours.
  List<Track> get upNext => _index + 1 >= _queue.length
      ? const []
      : List.unmodifiable(_queue.sublist(_index + 1));

  bool get hasNext => _index + 1 < _queue.length;

  @override
  void dispose() {
    _ticker?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _engine?.dispose();
    super.dispose();
  }

  static bool _same(Track a, Track b) {
    if (a.id.isNotEmpty && b.id.isNotEmpty) return a.id == b.id;
    return a.title == b.title && a.artist == b.artist;
  }

  void _bindEngine() {
    final engine = _engine;
    if (engine == null) return;

    _positionSub = engine.positionStream.listen((value) {
      if (_simulated) return;
      _position = value;
      notifyListeners();
    });

    _durationSub = engine.durationStream.listen((value) {
      if (_simulated || value == null || value == Duration.zero) return;
      _engineDuration = value;
      notifyListeners();
    });

    _playingSub = engine.playingStream.listen((value) {
      if (_simulated || value == _playing) return;
      _playing = value;
      notifyListeners();
    });

    _completedSub = engine.completedStream.listen((_) {
      if (_simulated) return;
      _advance();
    });
  }

  /// Lance [track]. S'il est déjà dans la file, on s'y déplace ; sinon on
  /// l'insère juste après le titre courant.
  void play(Track track) {
    if (_queue.isEmpty) {
      _queue.add(track);
      _index = 0;
    } else {
      final found = _queue.indexWhere((t) => _same(t, track));
      if (found >= 0) {
        _index = found;
      } else {
        _queue.insert(_index + 1, track);
        _index += 1;
      }
    }
    _startCurrent();
  }

  /// Lance le titre placé à [queueIndex] dans la file.
  void playAt(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= _queue.length) return;
    _index = queueIndex;
    _startCurrent();
  }

  /// Remplace la file par [tracks] et démarre [startAt] (le premier titre par
  /// défaut). Utilisé par « Tout lire » sur une catégorie ou un artiste.
  void playCollection(List<Track> tracks, {Track? startAt}) {
    if (tracks.isEmpty) return;
    final start = startAt == null
        ? 0
        : tracks.indexWhere((track) => _same(track, startAt));
    _queue
      ..clear()
      ..addAll(tracks);
    _index = start < 0 ? 0 : start;
    _startCurrent();
  }

  void toggle() {
    if (!hasSelection) return;
    _playing = !_playing;
    if (_simulated) {
      if (_playing) {
        _startTicker();
      } else {
        _stopTicker();
      }
    } else {
      _run(_playing ? _engine?.play() : _engine?.pause());
    }
    notifyListeners();
  }

  void next() {
    if (!hasSelection) return;
    _jump(_index + 1);
  }

  void previous() {
    if (!hasSelection) return;
    _jump(_index - 1);
  }

  void _jump(int target) {
    if (_queue.isEmpty) return;
    _index = (target % _queue.length + _queue.length) % _queue.length;
    _startCurrent();
  }

  /// Insère [track] juste après le titre en cours. S'il est déjà dans la
  /// file, il est déplacé à cette position.
  void playNext(Track track) {
    if (_queue.isEmpty) {
      _queue.add(track);
      _index = 0;
      notifyListeners();
      return;
    }
    final current = this.track;
    if (_same(track, current)) return;
    _queue.removeWhere((t) => _same(t, track));
    _index = _queue.indexWhere((t) => _same(t, current));
    _queue.insert(_index + 1, track);
    notifyListeners();
  }

  /// Ajoute [track] en fin de file. Renvoie `false` s'il y est déjà.
  bool addToQueue(Track track) {
    if (_queue.any((t) => _same(t, track))) return false;
    _queue.add(track);
    notifyListeners();
    return true;
  }

  /// Retire [track] des titres à venir (jamais le titre en cours).
  void removeUpNext(Track track) {
    final found = _queue.indexWhere((t) => _same(t, track), _index + 1);
    if (found < 0) return;
    _queue.removeAt(found);
    notifyListeners();
  }

  /// Réordonne les titres à venir. Les index sont relatifs à [upNext] et
  /// [newIndex] intègre déjà le décalage de l'élément retiré.
  void moveUpNext(int oldIndex, int newIndex) {
    final start = _index + 1;
    final length = _queue.length - start;
    if (oldIndex < 0 || oldIndex >= length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= length) newIndex = length - 1;
    if (newIndex == oldIndex) return;
    final item = _queue.removeAt(start + oldIndex);
    _queue.insert(start + newIndex, item);
    notifyListeners();
  }

  void seek(double value) {
    if (!hasSelection) return;
    final clamped = value.clamp(0.0, 1.0);
    if (_simulated) {
      _simulatedProgress = clamped;
    } else {
      _position = duration * clamped;
      _run(_engine?.seek(_position));
    }
    notifyListeners();
  }

  /// Démarre le titre en cours : l'état passe à « lecture » et la source est
  /// chargée de façon asynchrone.
  void _startCurrent() {
    _selected = true;
    _playing = true;
    _loadCurrent();
    notifyListeners();
  }

  Future<void> _loadCurrent() async {
    final token = ++_loadToken;
    _resetPlayback();

    final engine = _engine;
    final resolver = _resolver;
    if (engine == null || resolver == null || _queue.isEmpty) {
      _simulated = true;
      _simulatedProgress = 0;
      if (_playing) _startTicker();
      notifyListeners();
      return;
    }

    _simulated = false;
    try {
      final source = await resolver.resolve(track);
      if (token != _loadToken) return;
      if (source == null) {
        debugPrint('Aucune source audio pour ${track.audioPath}');
        _useSimulation(engine);
        return;
      }
      final loaded = await engine.setSource(
        source.uri,
        isAsset: source.isAsset,
      );
      if (token != _loadToken) return;
      _engineDuration = loaded;
      _position = Duration.zero;
      if (_playing) _run(engine.play());
      notifyListeners();
    } catch (error, stack) {
      debugPrint('Lecture impossible (${track.audioPath}) : $error\n$stack');
      if (token != _loadToken) return;
      _useSimulation(engine);
    }
  }

  /// Aucun audio exploitable : on garde l'interface vivante en simulant.
  void _useSimulation(AudioEngine engine) {
    _simulated = true;
    _simulatedProgress = 0;
    _engineDuration = null;
    _position = Duration.zero;
    _run(engine.stop());
    if (_playing) _startTicker();
    notifyListeners();
  }

  void _resetPlayback() {
    _stopTicker();
    _simulated = false;
    _simulatedProgress = 0;
    _position = Duration.zero;
    _engineDuration = null;
  }

  void _advance() {
    if (_queue.isEmpty) return;
    _index = (_index + 1) % _queue.length;
    _startCurrent();
  }

  void _startTicker() {
    if (_queue.isEmpty) return;
    _ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_playing || _queue.isEmpty || !_simulated) return;
      final totalMs = duration.inMilliseconds;
      if (totalMs <= 0) return;
      final nextValue = _simulatedProgress + 500 / totalMs;
      if (nextValue >= 1) {
        _advance();
      } else {
        _simulatedProgress = nextValue;
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Lance un appel audio sans propager une erreur asynchrone non gérée.
  void _run(Future<void>? future) {
    if (future == null) return;
    future.catchError((Object error, StackTrace stack) {
      debugPrint('Erreur audio : $error\n$stack');
    });
  }
}
