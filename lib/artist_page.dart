import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';

/// Fiche d'un artiste : tous ses morceaux disponibles.
///
/// Aucun titre ne démarre automatiquement : l'utilisateur choisit celui qu'il
/// veut écouter, puis la page se referme sur le lecteur.
class ArtistPage extends StatelessWidget {
  final Artist artist;
  final List<Track> tracks;
  final ValueChanged<Track> onPlay;

  const ArtistPage({
    super.key,
    required this.artist,
    required this.tracks,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final tint = artist.tint;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(tint, AppColors.bg, 0.48)!,
              AppColors.bg,
              AppColors.bg,
            ],
            stops: const [0, 0.38, 1],
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
                      'ARTISTE',
                      style: AppText.eyebrow.copyWith(
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tint.withAlpha(150),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tint.withAlpha(55),
                            blurRadius: 34,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Cover(
                        size: 132,
                        radius: 66,
                        image: artist.image,
                        tint: tint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      artist.name,
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
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: tracks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final track = tracks[i];
                    return _TrackTile(track: track, onTap: () => onPlay(track));
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

class _TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _TrackTile({required this.track, required this.onTap});

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
                      '${track.genre} · ${_format(track.duration)}',
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
