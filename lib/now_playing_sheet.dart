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
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => NowPlayingSheet(player: player),
  );
}

class NowPlayingSheet extends StatelessWidget {
  final PlayerController player;
  const NowPlayingSheet({super.key, required this.player});

  String _format(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Container(
      height: height * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: AnimatedBuilder(
        animation: player,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                    ),
                    const Expanded(
                      child: Text(
                        'EN LECTURE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final coverSize = math.min(
                        math.min(constraints.maxWidth, 340.0),
                        constraints.maxHeight * 0.46,
                      );
                      return Column(
                        children: [
                          const Spacer(flex: 2),
                          Center(
                            child: SizedBox(
                              width: coverSize,
                              height: coverSize,
                              child: Container(
                              width: coverSize,
                              height: coverSize,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(24)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 32,
                                    offset: Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Cover(
                                size: coverSize,
                                radius: 24,
                                image: player.track.image,
                              ),
                            ),
                            ),
                          ),
                          const Spacer(flex: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      player.track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.favorite_border_rounded,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              activeTrackColor: AppColors.green,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppColors.green,
                              overlayColor: AppColors.green.withAlpha(30),
                              thumbShape:
                                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: player.progress,
                              onChanged: player.seek,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_format(player.position),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white54)),
                                Text(_format(player.duration),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white54)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.shuffle_rounded,
                                    color: Colors.white60),
                              ),
                              IconButton(
                                onPressed: player.previous,
                                icon: const Icon(Icons.skip_previous_rounded, size: 38),
                              ),
                              IconButton.filled(
                                onPressed: player.toggle,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.playButton,
                                  foregroundColor: AppColors.yellow,
                                  padding: const EdgeInsets.all(18),
                                  side: BorderSide(color: Colors.white.withAlpha(28)),
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
                                icon: const Icon(Icons.skip_next_rounded, size: 38),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.repeat_rounded,
                                    color: Colors.white60),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
