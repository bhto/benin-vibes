import 'dart:ui';

import 'package:flutter/material.dart';
import 'data.dart';
import 'now_playing_sheet.dart';
import 'player_controller.dart';
import 'theme.dart';

/// Espace réservé sous le contenu pour laisser respirer la barre flottante.
const double _kBottomInset = 190;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _player = PlayerController();

  static const _titles = ['Accueil', 'Découvrir', 'Bibliothèque'];

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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _Backdrop(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Bonjour 👋', style: AppText.caption),
                          const SizedBox(height: 3),
                          Text(
                            _titles[_tab],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GlassIconButton(
                      icon: Icons.search_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _GlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {},
                      badge: true,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  HomePage(onPlay: _player.play, onPlayNext: _playNext),
                  DiscoverPage(onPlay: _player.play),
                  LibraryPage(onPlay: _player.play, onPlayNext: _playNext),
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
            MiniPlayer(
              player: _player,
              onOpen: () => showNowPlaying(context, _player),
            ),
            _FloatingNav(
              index: _tab,
              onSelect: (i) => setState(() => _tab = i),
            ),
          ],
        ),
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
              colors: [
                Color(0xFF0C1A13),
                AppColors.bg,
                AppColors.bg,
              ],
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
                  colors: [
                    AppColors.green.withAlpha(34),
                    Colors.transparent,
                  ],
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

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
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
  _NavSpec(Icons.library_music_outlined, Icons.library_music_rounded, 'Bibliothèque'),
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
            Icon(selected ? spec.activeIcon : spec.icon, size: 21, color: color),
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

  const MiniPlayer({
    super.key,
    required this.player,
    required this.onOpen,
  });

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
      icon: Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      ),
    );
  }
}

// ───────────────────────── Accueil ─────────────────────────

class HomePage extends StatelessWidget {
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;
  const HomePage({
    super.key,
    required this.onPlay,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: _kBottomInset),
      children: [
        const _SectionHeader('À la une'),
        _FeaturedRail(onPlay: onPlay),
        const _SectionHeader('Mix du jour'),
        _DailyMix(onPlay: onPlay),
        const _SectionHeader('Nouveautés'),
        _NewReleases(onPlay: onPlay, onPlayNext: onPlayNext),
        const _SectionHeader('Artistes populaires'),
        _ArtistRail(onPlay: onPlay),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
      child: Row(
        children: [
          Text(text, style: AppText.section),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Colors.white.withAlpha(80),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRail extends StatefulWidget {
  final void Function(Track) onPlay;
  const _FeaturedRail({required this.onPlay});

  @override
  State<_FeaturedRail> createState() => _FeaturedRailState();
}

class _FeaturedRailState extends State<_FeaturedRail> {
  static const _viewportFraction = 0.85;
  static const _cardCount = 3;

  late final PageController _controller =
      PageController(viewportFraction: _viewportFraction);

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
              final page = _controller.hasClients &&
                      _controller.position.haveDimensions
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
                      track: demoTracks[i],
                      onPlay: () => widget.onPlay(demoTracks[i]),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
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
  final void Function(Track) onPlay;
  const _DailyMix({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final track = demoTracks.first;
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
                Cover(
                  size: 72,
                  radius: 18,
                  image: track.image,
                  tint: tint,
                ),
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
                        'Sessimè, Fanicko, Zeynab et plus',
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
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;
  const _NewReleases({required this.onPlay, required this.onPlayNext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 202,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: demoTracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final t = demoTracks[(i + 2) % demoTracks.length];
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
  final void Function(Track) onPlay;
  const _ArtistRail({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: demoTracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final t = demoTracks[i];
          return GestureDetector(
            onTap: () => onPlay(t),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.tint.withAlpha(130), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: t.tint.withAlpha(30),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Cover(
                    size: 72,
                    radius: 36,
                    image: t.image,
                    tint: t.tint,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 84,
                  child: Text(
                    t.artist,
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

class DiscoverPage extends StatelessWidget {
  final void Function(Track) onPlay;
  const DiscoverPage({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, _kBottomInset),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            style: const TextStyle(fontSize: 14.5),
            decoration: InputDecoration(
              hintText: 'Artistes, titres, genres…',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.faint,
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 46, minHeight: 40),
            ),
          ),
        ),
        const _SectionHeader('Parcourir par genre'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: genres.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.95,
            ),
            itemBuilder: (_, i) => _GenreTile(
              label: genres[i],
              color: genreColors[i % genreColors.length],
              icon: genreIcons[i % genreIcons.length],
            ),
          ),
        ),
        const _SectionHeader('Artistes à suivre'),
        _ArtistRail(onPlay: onPlay),
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _GenreTile({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
            color: color.withAlpha(26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            bottom: -14,
            child: Transform.rotate(
              angle: -0.28,
              child: Icon(icon, size: 58, color: Colors.white.withAlpha(34)),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Bibliothèque ─────────────────────────

class LibraryPage extends StatelessWidget {
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;
  const LibraryPage({
    super.key,
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
                _TrackList(onPlay: onPlay, onPlayNext: onPlayNext),
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
  final void Function(Track) onPlay;
  final void Function(Track) onPlayNext;
  const _TrackList({required this.onPlay, required this.onPlayNext});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: _kBottomInset),
      itemCount: demoTracks.length,
      separatorBuilder: (_, _) => const Divider(
        indent: 112,
        endIndent: 24,
        height: 1,
      ),
      itemBuilder: (_, i) {
        final t = demoTracks[i];
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
                        t.artist,
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
