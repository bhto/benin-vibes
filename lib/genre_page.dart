import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';

/// Tous les morceaux d'un genre.
///
/// L'utilisateur peut lancer la catégorie entière avec « Tout lire » ou
/// choisir un titre précis. La file d'attente est alors limitée aux morceaux
/// de cette catégorie.
class GenrePage extends StatelessWidget {
  final Genre genre;
  final List<Track> tracks;
  final ValueChanged<Track> onPlay;
  final VoidCallback onPlayAll;

  const GenrePage({
    super.key,
    required this.genre,
    required this.tracks,
    required this.onPlay,
    required this.onPlayAll,
  });

  @override
  Widget build(BuildContext context) {
    final color = genre.color;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, AppColors.bg, 0.42)!,
              AppColors.bg,
              AppColors.bg,
            ],
            stops: const [0, 0.36, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    Text(
                      'GENRE',
                      style: AppText.eyebrow.copyWith(
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(color, Colors.black, 0.12)!,
                            Color.lerp(color, Colors.black, 0.6)!,
                          ],
                        ),
                        border: Border.all(color: color.withAlpha(120)),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(65),
                            blurRadius: 34,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Icon(
                        genre.icon,
                        size: 52,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      genre.name,
                      textAlign: TextAlign.center,
                      style: AppText.display.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tracks.length > 1
                          ? '${tracks.length} morceaux disponibles'
                          : '1 morceau disponible',
                      style: AppText.caption.copyWith(
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onPlayAll,
                        icon: const Icon(Icons.play_arrow_rounded, size: 23),
                        label: const Text('Tout lire'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.playButton,
                          foregroundColor: AppColors.bg,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: tracks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final track = tracks[i];
                    return _GenreTrackTile(
                      track: track,
                      onTap: () => onPlay(track),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _GenreTrackTile({required this.track, required this.onTap});

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Cover(size: 52, radius: 12, image: track.image, tint: track.tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 22,
                  color: AppColors.greenBright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
