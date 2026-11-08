import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/audio_source_resolver.dart';
import 'artist_page.dart';
import 'data.dart';
import 'genre_page.dart';
import 'now_playing_sheet.dart';
import 'player_controller.dart';
import 'theme.dart';

/// Espace réservé sous le contenu pour laisser respirer la barre flottante.
const double _kBottomInset = 190;

class HomeShell extends StatefulWidget {
  final Library library;
  final AudioEngine? audioEngine;
  final AudioSourceResolver? audioResolver;

  const HomeShell({
    super.key,
    required this.library,
    this.audioEngine,
    this.audioResolver,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  /// Sens du changement d'onglet : 1 vers la droite, -1 vers la gauche.
  int _titleDirection = 1;

  late final PlayerController _player;
  late String _greeting;
  Timer? _greetingTimer;

  static const _titles = ['Accueil', 'Découvrir', 'Bibliothèque'];

  @override
  void initState() {
    super.initState();
    _player = PlayerController(
      tracks: widget.library.tracks,
      engine: widget.audioEngine,
      resolver: widget.audioResolver,
    );
    _greeting = _greetingFor(DateTime.now());

    // Le salut suit le moment de la journée sans recréer le Shell.
    _greetingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final next = _greetingFor(DateTime.now());
      if (next != _greeting) setState(() => _greeting = next);
    });
  }

  static String _greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Bonjour 👋';
    if (hour >= 12 && hour < 18) return 'Bon après-midi ☀️';
    if (hour >= 18 && hour < 22) return 'Bonsoir 🌙';
    return 'Bonne nuit 🌙';
  }

  void _selectTab(int index) {
    if (index == _tab) return;
    setState(() {
      _titleDirection = index > _tab ? 1 : -1;
      _tab = index;
    });
  }

  /// Ouvre la fiche d'un artiste : l'utilisateur choisit lui-même le morceau.
  void _openArtist(Artist artist) {
    final tracks = widget.library.tracksForArtist(artist.slug);
    if (tracks.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistPage(
          artist: artist,
          tracks: tracks,
          onPlay: (track) {
            _player.playCollection(tracks, startAt: track);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Ouvre la fiche d'un genre : « Tout lire » ou choix d'un titre.
  void _openGenre(Genre genre) {
    final tracks = widget.library.tracksForGenre(genre.slug);
    if (tracks.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenrePage(
          genre: genre,
          tracks: tracks,
          onPlay: (track) {
            _player.playCollection(tracks, startAt: track);
            Navigator.of(context).pop();
          },
          onPlayAll: () {
            _player.playCollection(tracks);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _playNext(Track track) {
    _player.playNext(track);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('« ${track.title} » sera lu juste après.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 118),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Affiche la petite vue des notifications (un seul message statique).
  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.library.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Aucune musique disponible.\n'
              'Vérifie le seed de la bibliothèque.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: _Backdrop(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedHeader(
                        greeting: _greeting,
                        title: _titles[_tab],
                        titleIndex: _tab,
                        direction: _titleDirection,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: _showNotifications,
                      tooltip: 'Notifications',
                      badge: true,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _AnimatedIndexedStack(
                index: _tab,
                children: [
                  HomePage(
                    library: widget.library,
                    onPlay: _player.play,
                    onPlayNext: _playNext,
                    onOpenArtist: _openArtist,
                  ),
                  DiscoverPage(
                    library: widget.library,
                    onPlay: _player.play,
                    onOpenGenre: _openGenre,
                  ),
                  LibraryPage(
                    library: widget.library,
                    onPlay: _player.play,
                    onPlayNext: _playNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _player,
              builder: (context, _) {
                if (!_player.hasSelection) return const SizedBox.shrink();
                return MiniPlayer(
                  player: _player,
                  onOpen: () => showNowPlaying(context, _player),
                );
              },
            ),
            _FloatingNav(index: _tab, onSelect: _selectTab),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Header animé ─────────────────────────

/// Salut + titre d'onglet avec entrée en fondu, glissement et transition
/// directionnelle quand on change de menu.
class _AnimatedHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final int titleIndex;
  final int direction;

  const _AnimatedHeader({
    required this.greeting,
    required this.title,
    required this.titleIndex,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previousChildren, ?currentChild],
            ),
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(greeting);
              return ClipRect(
                child: FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, incoming ? 0.5 : -0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
              );
            },
            child: Text(
              greeting,
              key: ValueKey(greeting),
              style: AppText.caption.copyWith(
                color: AppColors.muted,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previousChildren, ?currentChild],
            ),
            transitionBuilder: (child, animation) {
              final incoming =
                  child.key == ValueKey('header-title-$titleIndex');
              return ClipRect(
                child: FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(
                        incoming ? 0.22 * direction : -0.22 * direction,
                        0,
                      ),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
              );
            },
            child: Text(
              title,
              key: ValueKey('header-title-$titleIndex'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title,
            ),
          ),
        ],
      ),
    );
  }
}

/// Garde l'état des pages (scroll, rails) tout en adoucissant le changement
/// d'onglet par un léger fondu et un glissement vertical.
class _AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedIndexedStack({required this.index, required this.children});

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: 1,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 1,
  ).animate(_curve);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void didUpdateWidget(covariant _AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}

// ───────────────────────── Décor de fond ─────────────────────────

class _Backdrop extends StatelessWidget {
  final Widget child;
  const _Backdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C1A13), AppColors.bg, AppColors.bg],
              stops: [0, 0.34, 1],
            ),
          ),
        ),
        Positioned(
          top: -170,
          right: -110,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.green.withAlpha(34), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  final String? tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size(42, 42),
        backgroundColor: Colors.white.withAlpha(12),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.stroke),
      ),
      icon: badge
          ? Badge(
              smallSize: 7,
              backgroundColor: AppColors.yellow,
              child: Icon(icon, size: 20),
            )
          : Icon(icon, size: 20),
    );
  }
}

// ───────────────────────── Notifications ─────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.green.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      size: 20,
                      color: AppColors.greenBright,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppText.section.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 message',
                          style: AppText.caption.copyWith(
                            color: Colors.white.withAlpha(130),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(14)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.greenBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenue sur Benin Vibes 👋',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toute la musique béninoise réunie au même endroit. '
                            'Choisis un morceau et bonne écoute !',
                            style: AppText.body.copyWith(fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Navigation flottante ─────────────────────────

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavSpec(this.icon, this.activeIcon, this.label);
}

const _navSpecs = [
  _NavSpec(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
  _NavSpec(Icons.explore_outlined, Icons.explore_rounded, 'Découvrir'),
  _NavSpec(
    Icons.library_music_outlined,
    Icons.library_music_rounded,
    'Bibliothèque',
  ),
];

class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _FloatingNav({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xC20B100E),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _navSpecs.length; i++)
                    Expanded(
                      child: _NavItem(
                        spec: _navSpecs[i],
                        selected: index == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.faint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.green.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? spec.activeIcon : spec.icon,
              size: 21,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Mini-lecteur ─────────────────────────

class MiniPlayer extends StatelessWidget {
  final PlayerController player;
  final VoidCallback onOpen;

  const MiniPlayer({super.key, required this.player, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: player,
      builder: (context, _) {
        final track = player.track;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(110),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xD90C1210),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpen,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                            child: Row(
                              children: [
                                Cover(
                                  size: 44,
                                  radius: 12,
                                  image: track.image,
                                  tint: track.tint,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                _RoundPlayButton(
                                  playing: player.playing,
                                  onTap: player.toggle,
                                  size: 38,
                                  iconSize: 22,
                                ),
                                IconButton(
                                  onPressed: player.next,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.skip_next_rounded,
                                    size: 24,
                                    color: Colors.white.withAlpha(190),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: player.progress,
                                minHeight: 2.4,
                                color: AppColors.green,
                                backgroundColor: Colors.white.withAlpha(20),
                              ),
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
        );
      },
    );
  }
}

class _RoundPlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _RoundPlayButton({
    required this.playing,
    required this.onTap,
    this.size = 42,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        fixedSize: Size(size, size),
        backgroundColor: AppColors.playButton,
        foregroundColor: Colors.black,
        padding: EdgeInsets.zero,
      ),
      iconSize: iconSize,
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

// ───────────────────────── Accueil ─────────────────────────

class HomePage extends StatelessWidget {
  final Library library;
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;
  final void Function(Artist) onOpenArtist;

  const HomePage({
    super.key,
    required this.library,
    required this.onPlay,
    required this.onPlayNext,
    required this.onOpenArtist,
  });

  @override
  Widget build(BuildContext context) {
    final featured = library.featuredTracks.isNotEmpty
        ? library.featuredTracks
        : library.tracks.take(5).toList(growable: false);
    final newReleases = library.newReleases.isNotEmpty
        ? library.newReleases
        : library.tracks;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: _kBottomInset),
      children: [
        if (featured.isNotEmpty) ...[
          const _SectionHeader('À la une'),
          _FeaturedRail(tracks: featured, onPlay: onPlay),
        ],
        if (library.tracks.isNotEmpty) ...[
          const _SectionHeader('Mix du jour'),
          _DailyMix(
            track: library.tracks.first,
            artists: library.artists,
            onPlay: onPlay,
          ),
        ],
        if (newReleases.isNotEmpty) ...[
          const _SectionHeader('Nouveautés'),
          _NewReleases(
            tracks: newReleases,
            onPlay: onPlay,
            onPlayNext: onPlayNext,
          ),
        ],
        if (library.artists.isNotEmpty) ...[
          const _SectionHeader('Artistes populaires'),
          _ArtistRail(artists: library.artists, onOpen: onOpenArtist),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const _SectionHeader(
    this.text, {
    this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text, style: AppText.section),
    );
  }
}

class _FeaturedRail extends StatefulWidget {
  final List<Track> tracks;
  final void Function(Track) onPlay;

  const _FeaturedRail({required this.tracks, required this.onPlay});

  @override
  State<_FeaturedRail> createState() => _FeaturedRailState();
}

class _FeaturedRailState extends State<_FeaturedRail> {
  static const _viewportFraction = 0.85;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );

  int get _cardCount => widget.tracks.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 228,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: _cardCount,
        physics: const PageScrollPhysics(),
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final page =
                  _controller.hasClients && _controller.position.haveDimensions
                  ? _controller.page ?? _controller.initialPage.toDouble()
                  : _controller.initialPage.toDouble();
              final distance = (page - i).abs().clamp(0.0, 1.0);
              final scale = 1 - 0.1 * distance;
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 24 : 7,
                  right: i == _cardCount - 1 ? 24 : 7,
                ),
                child: Transform.scale(
                  scale: scale,
                  child: RepaintBoundary(
                    child: _FeaturedCard(
                      track: widget.tracks[i],
                      onPlay: () => widget.onPlay(widget.tracks[i]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;
  const _FeaturedCard({required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final tint = track.tint;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.black, 0.55)!,
            Color.lerp(tint, Colors.black, 0.88)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (track.image != null)
            Image.asset(
              track.image!,
              fit: BoxFit.cover,
              cacheWidth: 700,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(20),
                  Colors.black.withAlpha(45),
                  Colors.black.withAlpha(220),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(70),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text('À LA UNE', style: AppText.eyebrow),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _RoundPlayButton(
                      playing: false,
                      onTap: onPlay,
                      size: 42,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Écouter',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMix extends StatelessWidget {
  final Track track;
  final List<Artist> artists;
  final void Function(Track) onPlay;

  const _DailyMix({
    required this.track,
    required this.artists,
    required this.onPlay,
  });

  String get _subtitle {
    final names = artists.take(3).map((artist) => artist.name).toList();
    return names.isEmpty ? 'Les sons du Bénin' : '${names.join(', ')} et plus';
  }

  @override
  Widget build(BuildContext context) {
    final tint = track.tint;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPlay(track),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(tint, AppColors.surface, 0.42)!,
                  Color.lerp(tint, AppColors.bg, 0.82)!,
                ],
              ),
              border: Border.all(color: Colors.white.withAlpha(22)),
            ),
            child: Row(
              children: [
                Cover(size: 72, radius: 18, image: track.image, tint: tint),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('POUR TOI', style: AppText.eyebrow),
                      const SizedBox(height: 5),
                      const Text(
                        'Mix Bénin',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RoundPlayButton(
                  playing: false,
                  onTap: () => onPlay(track),
                  size: 40,
                  iconSize: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewReleases extends StatelessWidget {
  final List<Track> tracks;
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;

  const _NewReleases({
    required this.tracks,
    required this.onPlay,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 202,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final t = tracks[i];
          return GestureDetector(
            onTap: () => onPlay(t),
            onLongPress: () => onPlayNext(t),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: t.tint.withAlpha(40),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Cover(
                      size: 148,
                      radius: 18,
                      image: t.image,
                      tint: t.tint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArtistRail extends StatelessWidget {
  final List<Artist> artists;
  final void Function(Artist) onOpen;

  const _ArtistRail({required this.artists, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final artist = artists[i];
          return GestureDetector(
            onTap: () => onOpen(artist),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: artist.tint.withAlpha(130),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: artist.tint.withAlpha(30),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Cover(
                    size: 72,
                    radius: 36,
                    image: artist.image,
                    tint: artist.tint,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 84,
                  child: Text(
                    artist.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Découvrir ─────────────────────────

class DiscoverPage extends StatefulWidget {
  final Library library;
  final void Function(Track) onPlay;
  final void Function(Genre) onOpenGenre;

  const DiscoverPage({
    super.key,
    required this.library,
    required this.onPlay,
    required this.onOpenGenre,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final TextEditingController _searchController;
  late final List<Track> _suggestions;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    final shuffled = List<Track>.of(widget.library.tracks)..shuffle();
    _suggestions = shuffled.take(4).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final next = value.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final results = searching ? widget.library.search(_query) : const <Track>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, _kBottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14.5),
            decoration: InputDecoration(
              hintText: 'Artistes, titres, genres…',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.faint,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 40,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.faint,
                      ),
                    ),
            ),
          ),
        ),
        if (searching) ...[
          if (results.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 2),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 25,
                      color: AppColors.faint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun titre trouvé',
                    style: AppText.section.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Essaie un autre mot ou choisis une suggestion.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: Colors.white.withAlpha(130),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionHeader(
              'Suggestions',
              padding: EdgeInsets.fromLTRB(24, 20, 24, 6),
            ),
            for (final track in _suggestions)
              _SearchTrackTile(track: track, onTap: () => widget.onPlay(track)),
          ] else ...[
            _SectionHeader(
              results.length > 1
                  ? '${results.length} titres trouvés'
                  : '1 titre trouvé',
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
            ),
            for (final track in results)
              _SearchTrackTile(track: track, onTap: () => widget.onPlay(track)),
          ],
        ] else if (widget.library.genres.isNotEmpty) ...[
          const _SectionHeader(
            'Parcourir par genre',
            padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.library.genres.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (_, i) {
                final genre = widget.library.genres[i];
                return _GenreTile(
                  genre: genre,
                  trackCount: widget.library.tracksForGenre(genre.slug).length,
                  onTap: () => widget.onOpenGenre(genre),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _SearchTrackTile({required this.track, required this.onTap});

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: Colors.white.withAlpha(7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Cover(
                  size: 46,
                  radius: 10,
                  image: track.image,
                  tint: track.tint,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.artist} · ${_format(track.duration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.green.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: AppColors.greenBright,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreTile extends StatelessWidget {
  final Genre genre;
  final int trackCount;
  final VoidCallback onTap;

  const _GenreTile({
    required this.genre,
    required this.trackCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = genre.color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.black, 0.18)!,
              Color.lerp(color, Colors.black, 0.62)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(34),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -18,
              child: Transform.rotate(
                angle: -0.28,
                child: Icon(
                  genre.icon,
                  size: 78,
                  color: Colors.white.withAlpha(36),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  genre.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  trackCount > 1 ? '$trackCount titres' : '$trackCount titre',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Bibliothèque ─────────────────────────

class LibraryPage extends StatelessWidget {
  final Library library;
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;

  const LibraryPage({
    super.key,
    required this.library,
    required this.onPlay,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'Favoris'),
              Tab(text: 'Playlists'),
              Tab(text: 'Téléchargés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TrackList(
                  tracks: library.tracks,
                  onPlay: onPlay,
                  onPlayNext: onPlayNext,
                ),
                const _EmptyState(
                  icon: Icons.queue_music_rounded,
                  title: 'Aucune playlist',
                  message: 'Crée ta première playlist et retrouve-la ici.',
                  action: 'Créer une playlist',
                ),
                const _EmptyState(
                  icon: Icons.cloud_download_rounded,
                  title: 'Rien de téléchargé',
                  message: 'Télécharge des titres pour écouter sans connexion.',
                  action: 'Parcourir les titres',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final List<Track> tracks;
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;

  const _TrackList({
    required this.tracks,
    required this.onPlay,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: _kBottomInset),
      itemCount: tracks.length,
      separatorBuilder: (_, _) =>
          const Divider(indent: 112, endIndent: 24, height: 1),
      itemBuilder: (_, i) {
        final t = tracks[i];
        return InkWell(
          onTap: () => onPlay(t),
          onLongPress: () => onPlayNext(t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.faint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Cover(size: 52, radius: 12, image: t.image, tint: t.tint),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.artist} · ${t.genre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: AppColors.faint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, _kBottomInset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Icon(icon, size: 30, color: AppColors.green),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: () {}, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
