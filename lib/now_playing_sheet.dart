import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';
import 'player_controller.dart';
import 'theme.dart';

/// Ouvre la vue « en cours de lecture », qui sort du bas de l'écran.
Future<void> showNowPlaying(BuildContext context, PlayerController player) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    builder: (_) => NowPlayingSheet(player: player),
  );
}

class NowPlayingSheet extends StatefulWidget {
  final PlayerController player;
  const NowPlayingSheet({super.key, required this.player});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

/// Les trois panneaux du lecteur plein écran.
enum _Panel { artwork, lyrics, queue }

class _NowPlayingSheetState extends State<NowPlayingSheet> {
  _Panel _panel = _Panel.artwork;
  int _lastActive = -1;
  String? _lastTitle;
  final Map<int, GlobalKey> _lineKeys = {};

  /// Suit la liste de paroles pour pouvoir la recentrer.
  final ScrollController _lyricsScroll = ScrollController();

  /// Vrai tant que le défilement automatique suit la chanson. Passe à faux
  /// dès que l'utilisateur fait défiler les paroles lui-même.
  bool _lyricsFollowing = true;

  PlayerController get player => widget.player;

  String get _panelTitle => switch (_panel) {
    _Panel.artwork => 'EN LECTURE',
    _Panel.lyrics => 'PAROLES',
    _Panel.queue => "FILE D'ATTENTE",
  };

  String _format(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  void _togglePanel(_Panel panel) {
    setState(() {
      _panel = _panel == panel ? _Panel.artwork : panel;
      _lastActive = -1;
    });
  }

  /// Légère avance (100 ms) pour compenser le temps de transition visuelle
  /// et aligner parfaitement l'illumination du texte avec la voix.
  static const _kSyncOffset = Duration(milliseconds: 100);

  int _activeIndex(List<LyricLine> lines) {
    if (lines.isEmpty) return -1;
    final position = player.position + _kSyncOffset;
    if (position < lines.first.time) return -1;
    var index = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  GlobalKey _lineKey(int i) =>
      _lineKeys.putIfAbsent(i, () => GlobalKey(debugLabel: 'lyric-$i'));

  void _scrollToActive(int index, {bool force = false}) {
    if (index < 0) {
      // Avant la première ligne (introduction musicale), le recentrage
      // ramène simplement en haut de la liste.
      if (!force) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_lyricsScroll.hasClients) return;
        _lyricsScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }
    if (!force && _lastActive == index) return;
    _lastActive = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _lineKeys[index]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.34,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Pause le suivi automatique dès un geste de défilement de l'utilisateur.
  bool _onLyricsScroll(ScrollNotification notification) {
    final dragging =
        (notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) ||
        (notification is OverscrollNotification &&
            notification.dragDetails != null);
    if (dragging && _lyricsFollowing) {
      setState(() => _lyricsFollowing = false);
    }
    return false;
  }

  /// Reprend le suivi et recentre la ligne en train d'être chantée.
  void _followLyrics() {
    final active = _activeIndex(player.track.lyrics);
    setState(() {
      _lyricsFollowing = true;
      _lastActive = -1;
    });
    _scrollToActive(active, force: true);
  }

  @override
  void dispose() {
    _lyricsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: player,
      builder: (context, _) {
        final track = player.track;
        final tint = track.tint;
        if (_lastTitle != track.title) {
          _lastTitle = track.title;
          _lastActive = -1;
          _lyricsFollowing = true;
          if (_panel == _Panel.lyrics && !track.hasLyrics) {
            _panel = _Panel.artwork;
          }
        }
        return Container(
          height: height * 0.94,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(tint, Colors.black, 0.58)!,
                Color.lerp(tint, Colors.black, 0.86)!,
                AppColors.bg,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -180,
                left: -80,
                right: -80,
                child: IgnorePointer(
                  child: Container(
                    height: 420,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          tint.withAlpha(90),
                          tint.withAlpha(20),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: SizedBox(
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Le titre est centré sur toute la largeur, que le
                            // bouton Paroles soit présent ou non.
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 96,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _panelTitle,
                                    key: ValueKey(_panel),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppText.eyebrow,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  fixedSize: const Size(38, 38),
                                  backgroundColor: Colors.white.withAlpha(14),
                                  foregroundColor: AppColors.text,
                                  side: const BorderSide(
                                    color: AppColors.stroke,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 24,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: _panel == _Panel.queue
                                        ? 'Afficher la pochette'
                                        : "Afficher la file d'attente",
                                    onPressed: () => _togglePanel(_Panel.queue),
                                    icon: Icon(
                                      Icons.queue_music_rounded,
                                      size: 21,
                                      color: _panel == _Panel.queue
                                          ? AppColors.green
                                          : AppColors.muted,
                                    ),
                                  ),
                                  if (track.hasLyrics)
                                    IconButton(
                                      tooltip: _panel == _Panel.lyrics
                                          ? 'Afficher la pochette'
                                          : 'Afficher les paroles',
                                      onPressed: () =>
                                          _togglePanel(_Panel.lyrics),
                                      icon: Icon(
                                        _panel == _Panel.lyrics
                                            ? Icons.album_rounded
                                            : Icons.lyrics_rounded,
                                        size: 22,
                                        color: _panel == _Panel.lyrics
                                            ? AppColors.green
                                            : AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: switch (_panel) {
                          _Panel.artwork => const EdgeInsets.fromLTRB(
                            32,
                            10,
                            32,
                            6,
                          ),
                          _Panel.lyrics => const EdgeInsets.fromLTRB(
                            18,
                            4,
                            12,
                            4,
                          ),
                          _Panel.queue => const EdgeInsets.fromLTRB(
                            12,
                            4,
                            12,
                            4,
                          ),
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.965,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: switch (_panel) {
                            _Panel.artwork => KeyedSubtree(
                              key: const ValueKey('artwork'),
                              child: _buildArtwork(track, tint),
                            ),
                            _Panel.lyrics => KeyedSubtree(
                              key: const ValueKey('lyrics'),
                              child: _buildLyrics(track),
                            ),
                            _Panel.queue => KeyedSubtree(
                              key: const ValueKey('queue'),
                              child: _buildQueue(),
                            ),
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xB3FFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: player.isLiked(track)
                                ? 'Retirer des favoris'
                                : 'Ajouter aux favoris',
                            onPressed: () => player.toggleLike(),
                            icon: Icon(
                              player.isLiked(track)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 24,
                              color: player.isLiked(track)
                                  ? AppColors.red
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.4,
                        activeTrackColor: AppColors.green,
                        inactiveTrackColor: Colors.white.withAlpha(38),
                        thumbColor: AppColors.text,
                        overlayColor: AppColors.green.withAlpha(28),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Slider(
                          value: player.progress,
                          onChanged: player.seek,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _format(player.position),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.faint,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _format(player.duration),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.faint,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: player.shuffle
                                ? 'Désactiver la lecture aléatoire'
                                : 'Lecture aléatoire',
                            onPressed: player.toggleShuffle,
                            style: IconButton.styleFrom(
                              backgroundColor: player.shuffle
                                  ? AppColors.green.withAlpha(26)
                                  : null,
                            ),
                            icon: Icon(
                              Icons.shuffle_rounded,
                              size: 22,
                              color: player.shuffle
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                          ),
                          IconButton(
                            onPressed: player.previous,
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            onPressed: player.toggle,
                            style: IconButton.styleFrom(
                              fixedSize: const Size(72, 72),
                              backgroundColor: AppColors.playButton,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                            ),
                            iconSize: 40,
                            icon: Icon(
                              player.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          IconButton(
                            onPressed: player.next,
                            icon: const Icon(Icons.skip_next_rounded, size: 36),
                          ),
                          IconButton(
                            tooltip: player.repeat
                                ? 'Désactiver la répétition'
                                : 'Répéter la file',
                            onPressed: player.toggleRepeat,
                            style: IconButton.styleFrom(
                              backgroundColor: player.repeat
                                  ? AppColors.green.withAlpha(26)
                                  : null,
                            ),
                            icon: Icon(
                              Icons.repeat_rounded,
                              size: 22,
                              color: player.repeat
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 0, 30, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.volume_down_rounded,
                            size: 18,
                            color: AppColors.faint,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.4,
                                activeTrackColor: Colors.white.withAlpha(120),
                                inactiveTrackColor: Colors.white.withAlpha(28),
                                thumbColor: Colors.white.withAlpha(200),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 3.5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value: player.volume,
                                onChanged: player.setVolume,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                            color: AppColors.faint,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtwork(Track track, Color tint) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight - 10),
          330.0,
        );
        return Center(
          child: GestureDetector(
            onTap: track.hasLyrics ? () => _togglePanel(_Panel.lyrics) : null,
            child: SizedBox(
              width: coverSize,
              height: coverSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(130),
                            blurRadius: 44,
                            offset: const Offset(0, 22),
                          ),
                          BoxShadow(
                            color: tint.withAlpha(70),
                            blurRadius: 70,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Cover(
                        size: coverSize,
                        radius: 28,
                        image: track.image,
                        tint: tint,
                      ),
                    ),
                  ),
                  if (track.hasLyrics)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(38),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lyrics_rounded,
                                size: 14,
                                color: Colors.white.withAlpha(215),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Paroles',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(225),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueue() {
    final upNext = player.upNext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: Text('EN LECTURE', style: AppText.eyebrow),
        ),
        _QueueTile(
          track: player.track,
          current: true,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 18,
              color: AppColors.green,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 22, 8, 6),
          child: Row(
            children: [
              const Text('À SUIVRE', style: AppText.eyebrow),
              const Spacer(),
              Text(
                upNext.length > 1
                    ? '${upNext.length} titres'
                    : upNext.length == 1
                    ? '1 titre'
                    : '',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.faint,
                ),
              ),
            ],
          ),
        ),
        if (upNext.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Aucun titre à suivre.\n'
                  'Appuie longuement sur un morceau pour le lire ensuite.',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              physics: const BouncingScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: upNext.length,
              onReorderItem: player.moveUpNext,
              itemBuilder: (context, i) {
                final t = upNext[i];
                return Padding(
                  key: ValueKey('up-next-${t.title}-${t.artist}'),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _QueueTile(
                    track: t,
                    onTap: () => player.playAt(player.index + 1 + i),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: AppColors.faint,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retirer de la file',
                          onPressed: () => player.removeUpNext(t),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLyrics(Track track) {
    final lines = track.lyrics;
    if (lines.isEmpty) {
      return Center(
        child: Text(
          'Paroles indisponibles pour ce titre.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
      );
    }
    final active = _activeIndex(lines);
    if (_lyricsFollowing) _scrollToActive(active);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onLyricsScroll,
          // Toutes les lignes sont construites, même hors écran : sans cela,
          // une ligne éloignée du viewport n'existe pas dans l'arbre et
          // « Revenir aux paroles » ne peut pas la recentrer quand le décalage
          // est important. Une chanson compte quelques dizaines de lignes.
          child: SingleChildScrollView(
            controller: _lyricsScroll,
            padding: const EdgeInsets.only(top: 6, bottom: 64),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++)
                  _lyricLine(lines[i], i, i == active),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _lyricsFollowing
                ? const SizedBox.shrink()
                : Center(
                    key: const ValueKey('lyrics-follow'),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _followLyrics,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(175),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.my_location_rounded,
                                size: 15,
                                color: AppColors.greenBright,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Revenir aux paroles',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  color: Colors.white.withAlpha(225),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Une ligne de paroles cliquable pour déplacer la lecture à cet instant.
  Widget _lyricLine(LyricLine line, int index, bool isActive) {
    return GestureDetector(
      key: _lineKey(index),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final total = player.duration.inMilliseconds;
        if (total <= 0) return;
        player.seek(line.time.inMilliseconds / total);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 3,
              height: 24,
              margin: const EdgeInsets.only(top: 5, right: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isActive ? 21 : 17,
                  height: 1.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isActive ? -0.3 : 0,
                  color: isActive ? AppColors.text : Colors.white.withAlpha(92),
                ),
                child: Text(line.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne de la file d'attente.
class _QueueTile extends StatelessWidget {
  final Track track;
  final bool current;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _QueueTile({
    required this.track,
    this.current = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          decoration: BoxDecoration(
            color: current ? Colors.white.withAlpha(16) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: current
                ? Border.all(color: AppColors.green.withAlpha(70))
                : null,
          ),
          child: Row(
            children: [
              Cover(size: 44, radius: 10, image: track.image, tint: track.tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: current ? AppColors.green : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
