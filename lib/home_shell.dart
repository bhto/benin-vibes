import 'package:flutter/material.dart';
import 'data.dart';
import 'now_playing_sheet.dart';
import 'player_controller.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _player = PlayerController();

  static const _titles = ['Accueil', 'Découvrir', 'Bibliothèque'];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bonjour 👋',
              style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              _titles[_tab],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Badge(
              smallSize: 9,
              backgroundColor: AppColors.red,
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          HomePage(onPlay: _player.play),
          DiscoverPage(onPlay: _player.play),
          LibraryPage(onPlay: _player.play),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(
              player: _player,
              onOpen: () => showNowPlaying(context, _player),
            ),
            NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Découvrir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Bibliothèque',
                ),
              ],
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
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                    child: Row(
                      children: [
                        Cover(size: 46, radius: 10, image: track.image),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: player.toggle,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.playButton,
                            foregroundColor: AppColors.yellow,
                            side: BorderSide(color: Colors.white.withAlpha(28)),
                          ),
                          icon: Icon(
                            player.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        IconButton(
                          onPressed: player.next,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: player.progress,
                    minHeight: 2.5,
                    color: AppColors.green,
                    backgroundColor: Colors.white12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Accueil ─────────────────────────

class HomePage extends StatelessWidget {
  final void Function(Track) onPlay;
  const HomePage({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const _SectionTitle('À la une'),
        _FeaturedRail(onPlay: onPlay),
        const _SectionTitle('Nouveautés'),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: demoTracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final t = demoTracks[(i + 2) % demoTracks.length];
              return GestureDetector(
                onTap: () => onPlay(t),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Cover(size: 140, radius: 16, image: t.image),
                      const SizedBox(height: 8),
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const _SectionTitle('Artistes populaires'),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: demoTracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final t = demoTracks[i];
              return Column(
                children: [
                  Cover(size: 76, radius: 38, image: t.image),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      t.artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
  static const _viewportFraction = 0.86;
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
      height: 190,
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
                  left: i == 0 ? 20 : 7,
                  right: i == _cardCount - 1 ? 20 : 7,
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceHigh,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (track.image != null)
            Image.asset(
              track.image!,
              fit: BoxFit.cover,
              cacheWidth: 600,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          if (track.image != null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black26, Colors.black87],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('À LA UNE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          Text(track.artist,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: onPlay,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.playButton,
                        foregroundColor: AppColors.yellow,
                        side: BorderSide(color: Colors.white.withAlpha(28)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Artistes, titres, genres…',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Genres', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(14),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: genreColors[i % genreColors.length],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(genres[i],
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Bibliothèque ─────────────────────────

class LibraryPage extends StatelessWidget {
  final void Function(Track) onPlay;
  const LibraryPage({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: AppColors.yellow,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
            tabs: [Tab(text: 'Favoris'), Tab(text: 'Playlists'), Tab(text: 'Téléchargés')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TrackList(onPlay: onPlay),
                const Center(child: Text('Tes playlists apparaîtront ici')),
                const Center(child: Text('Tes téléchargements apparaîtront ici')),
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
  const _TrackList({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: demoTracks.length,
      itemBuilder: (_, i) {
        final t = demoTracks[i];
        return ListTile(
          onTap: () => onPlay(t),
          leading: Cover(size: 48, radius: 10, image: t.image),
          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(t.artist, style: const TextStyle(color: Colors.white60)),
          trailing: const Icon(Icons.more_vert_rounded),
        );
      },
    );
  }
}
