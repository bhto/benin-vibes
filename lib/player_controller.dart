import 'dart:async';

import 'package:flutter/foundation.dart';
import 'data.dart';

/// État de lecture partagé entre le mini-lecteur, la vue plein écran, les
/// paroles et la file d'attente. La progression est simulée ici ; elle sera
/// remplacée par `just_audio` lors du branchement sur les fichiers réels.
class PlayerController extends ChangeNotifier {
  static const trackDuration = Duration(minutes: 3, seconds: 58);

  final List<Track> _queue = List<Track>.of(demoTracks);
  int _index = 0;
  bool _playing = false;
  double _progress = 0;
  Timer? _ticker;

  Track get track => _queue[_index];
  bool get playing => _playing;
  double get progress => _progress;

  Duration get duration => trackDuration;
  Duration get position => trackDuration * _progress;

  /// Toute la file, dans l'ordre de lecture.
  List<Track> get queue => List.unmodifiable(_queue);

  /// Index du titre en cours dans [queue].
  int get index => _index;

  /// Les titres qui seront lus après le morceau en cours.
  List<Track> get upNext =>
      _index + 1 >= _queue.length
          ? const []
          : List.unmodifiable(_queue.sublist(_index + 1));

  bool get hasNext => _index + 1 < _queue.length;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static bool _same(Track a, Track b) =>
      a.title == b.title && a.artist == b.artist;

  /// Lance [track]. S'il est déjà dans la file, on s'y déplace ; sinon on
  /// l'insère juste après le titre courant.
  void play(Track track) {
    final found = _queue.indexWhere((t) => _same(t, track));
    if (found >= 0) {
      _index = found;
    } else {
      _queue.insert(_index + 1, track);
      _index += 1;
    }
    _progress = 0;
    _playing = true;
    _startTicker();
    notifyListeners();
  }

  /// Lance le titre placé à [queueIndex] dans la file.
  void playAt(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= _queue.length) return;
    _index = queueIndex;
    _progress = 0;
    _playing = true;
    _startTicker();
    notifyListeners();
  }

  void toggle() {
    _playing = !_playing;
    if (_playing) {
      _startTicker();
    } else {
      _stopTicker();
    }
    notifyListeners();
  }

  void next() => _jump(_index + 1);

  void previous() => _jump(_index - 1);

  void _jump(int target) {
    if (_queue.isEmpty) return;
    _index = (target % _queue.length + _queue.length) % _queue.length;
    _progress = 0;
    _playing = true;
    _startTicker();
    notifyListeners();
  }

  /// Insère [track] juste après le titre en cours. S'il est déjà dans la
  /// file, il est déplacé à cette position.
  void playNext(Track track) {
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
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_playing) return;
      final step = 0.5 / trackDuration.inSeconds;
      final nextValue = _progress + step;
      if (nextValue >= 1) {
        _progress = 0;
        _index = (_index + 1) % _queue.length;
      } else {
        _progress = nextValue;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
