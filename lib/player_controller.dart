import 'package:flutter/foundation.dart';
import 'data.dart';

/// État de lecture partagé entre le mini-lecteur et la vue plein écran.
/// Sera branché sur just_audio plus tard.
class PlayerController extends ChangeNotifier {
  static const trackDuration = Duration(minutes: 3, seconds: 58);

  Track _track = demoTracks.first;
  bool _playing = true;
  double _progress = 0.35;

  Track get track => _track;
  bool get playing => _playing;
  double get progress => _progress;

  Duration get duration => trackDuration;
  Duration get position => trackDuration * _progress;

  void play(Track track) {
    _track = track;
    _progress = 0;
    _playing = true;
    notifyListeners();
  }

  void toggle() {
    _playing = !_playing;
    notifyListeners();
  }

  void next() {
    final i = demoTracks.indexOf(_track);
    play(demoTracks[(i + 1) % demoTracks.length]);
  }

  void previous() {
    final i = demoTracks.indexOf(_track);
    play(demoTracks[(i - 1 + demoTracks.length) % demoTracks.length]);
  }

  void seek(double value) {
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }
}
