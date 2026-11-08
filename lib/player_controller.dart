import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio/audio_engine.dart';
import 'audio/audio_source_resolver.dart';
import 'data.dart';
import 'database/library_repository.dart';

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
  final MusicRepository? _repository;

  /// Tous les morceaux connus, pour retrouver un favori même s'il a quitté la
  /// file d'attente.
  final Map<String, Track> _catalog;

  /// Identifiants des morceaux aimés.
  final Set<String> _liked;

  /// Ordre de la file avant activation du mode aléatoire.
  List<Track>? _shuffleOrigin;

  int _index = 0;
  bool _playing = false;
  bool _selected = false;
  bool _ended = false;
  bool _shuffle = false;
  bool _repeat = false;
  double _volume = 0.65;

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

  /// Vrai pendant le chargement d'une source.
  ///
  /// Les événements « lecture en pause » émis par le moteur pendant le
  /// remplacement d'une piste ne doivent pas annuler l'intention de lecture.
  bool _loading = false;

  Timer? _ticker;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<void>? _completedSub;

  PlayerController({
    required List<Track> tracks,
    AudioEngine? engine,
    AudioSourceResolver? resolver,
    MusicRepository? repository,
  }) : _queue = List<Track>.of(tracks),
       _catalog = {for (final track in tracks) track.id: track},
       _liked = {
         for (final track in tracks)
           if (track.liked) track.id,
       },
       _engine = engine,
       // Le champ privé ne peut pas être un paramètre nommé public.
       // ignore: prefer_initializing_formals
       _repository = repository,
       _resolver = engine == null ? null : (resolver ?? AudioSourceResolver()) {
    _bindEngine();
    _run(_engine?.setVolume(_volume));
  }

  Track get track => _queue[_index];
  bool get playing => _playing;

  /// Vrai lorsque le mode aléatoire mélange les titres à venir.
  bool get shuffle => _shuffle;

  /// Vrai lorsque la file revient au début après le dernier titre.
  bool get repeat => _repeat;

  /// Volume appliqué au moteur, entre 0 et 1.
  double get volume => _volume;

  /// Vrai si [track] a été ajouté aux favoris.
  bool isLiked(Track track) => _liked.contains(track.id);

  /// Les morceaux aimés, dans l'ordre de la bibliothèque.
  List<Track> get favorites => [
    for (final track in _catalog.values)
      if (_liked.contains(track.id)) track,
  ];

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
      if (_simulated || _loading || value == _playing) return;
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

    if (_shuffle) {
      _shuffleOrigin = List<Track>.of(_queue);
      final upcoming = _queue.sublist(_index + 1)..shuffle();
      _queue
        ..removeRange(_index + 1, _queue.length)
        ..addAll(upcoming);
    }

    _startCurrent();
  }

  void toggle() {
    if (!hasSelection) return;
    if (_ended) {
      _index = 0;
      _startCurrent();
      return;
    }
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

  /// Active ou coupe le mode aléatoire.
  ///
  /// À l'activation, les titres à venir sont mélangés alors que le morceau en
  /// cours reste en place. À la désactivation, l'ordre d'origine est restauré
  /// quand il est encore connu.
  void toggleShuffle() {
    _shuffle = !_shuffle;

    if (_queue.isNotEmpty) {
      if (_shuffle) {
        _shuffleOrigin = List<Track>.of(_queue);
        final upcoming = _queue.sublist(_index + 1)..shuffle();
        _queue
          ..removeRange(_index + 1, _queue.length)
          ..addAll(upcoming);
      } else {
        final origin = _shuffleOrigin;
        _shuffleOrigin = null;
        if (origin != null) {
          final current = track;
          final position = origin.indexWhere((t) => _same(t, current));
          if (position >= 0) {
            _queue
              ..clear()
              ..addAll(origin);
            _index = position;
          }
        }
      }
    }

    notifyListeners();
  }

  /// Active ou coupe la répétition de la file.
  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  /// Change le volume du moteur (0 = muet, 1 = maximum).
  void setVolume(double value) {
    final next = value.clamp(0.0, 1.0);
    if (next == _volume) return;
    _volume = next;
    _run(_engine?.setVolume(next));
    notifyListeners();
  }

  /// Ajoute ou retire le morceau en cours des favoris et persiste le choix.
  Future<void> toggleLike() async {
    if (_queue.isEmpty) return;
    final current = track;
    if (!_liked.remove(current.id)) _liked.add(current.id);
    notifyListeners();

    final repository = _repository;
    if (repository == null) return;
    try {
      await repository.setLiked(current.id, _liked.contains(current.id));
    } catch (error, stack) {
      debugPrint('Favori non enregistré : $error\n$stack');
    }
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
    _ended = false;
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
    _ended = false;
    _loadCurrent();
    notifyListeners();
  }

  Future<void> _loadCurrent() async {
    final token = ++_loadToken;
    _loading = true;
    _resetPlayback();

    final engine = _engine;
    final resolver = _resolver;
    if (engine == null || resolver == null || _queue.isEmpty) {
      _simulated = true;
      _simulatedProgress = 0;
      if (_playing) _startTicker();
      _loading = false;
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
      await engine.setVolume(_volume);
      if (token != _loadToken) return;
      _engineDuration = loaded;
      _position = Duration.zero;
      if (_playing) _run(engine.play());
      notifyListeners();
    } catch (error, stack) {
      debugPrint('Lecture impossible (${track.audioPath}) : $error\n$stack');
      if (token != _loadToken) return;
      _useSimulation(engine);
    } finally {
      if (token == _loadToken) _loading = false;
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

    if (_index + 1 < _queue.length) {
      _index += 1;
      _startCurrent();
      return;
    }

    if (_repeat) {
      _index = 0;
      _startCurrent();
      return;
    }

    // Fin de file sans répétition : on s'arrête sur le dernier titre.
    _playing = false;
    _ended = true;
    _simulatedProgress = 1;
    _stopTicker();
    notifyListeners();
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
