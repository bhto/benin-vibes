import 'package:flutter/material.dart';

import 'theme.dart';

/// Une ligne de paroles horodatée.
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine(this.time, this.text);
}

/// Un morceau de la bibliothèque locale.
///
/// Les métadonnées viennent de SQLite ; l'audio, la pochette et les paroles
/// sont des assets compilés avec l'application.
class Track {
  final String id;
  final String title;
  final String artist;
  final String artistSlug;
  final String genre;
  final String genreSlug;
  final String? image;
  final Color tint;
  final List<LyricLine> lyrics;
  final bool lyricsSynced;

  /// Chemin de l'audio dans la bibliothèque, ex.
  /// `audio/angelique_kidjo_agolo.mp3`. Le fichier correspondant est embarqué
  /// dans `assets/audio/`.
  final String audioPath;

  final Duration duration;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistSlug,
    required this.genre,
    required this.genreSlug,
    required this.audioPath,
    required this.duration,
    this.image,
    this.tint = AppColors.green,
    this.lyrics = const [],
    this.lyricsSynced = false,
  });

  bool get hasLyrics => lyrics.isNotEmpty;

  bool get hasSyncedLyrics => lyricsSynced && lyrics.isNotEmpty;
}

/// Un artiste de la bibliothèque.
class Artist {
  final int id;
  final String slug;
  final String name;
  final String? image;
  final Color tint;

  const Artist({
    required this.id,
    required this.slug,
    required this.name,
    this.image,
    this.tint = AppColors.green,
  });
}

/// Un genre musical, référencé par la table `genres`.
class Genre {
  final int id;
  final String slug;
  final String name;
  final Color color;
  final IconData icon;

  const Genre({
    required this.id,
    required this.slug,
    required this.name,
    required this.color,
    required this.icon,
  });
}

/// Tout ce dont l'interface a besoin : artistes, genres et morceaux.
class Library {
  final List<Artist> artists;
  final List<Genre> genres;
  final List<Track> tracks;

  /// Morceaux tirés au sort dans la base SQLite pour la section « À la une ».
  final List<Track> featuredTracks;

  /// Morceaux tirés au sort dans la base SQLite pour la section « Nouveautés ».
  final List<Track> newReleases;

  const Library({
    required this.artists,
    required this.genres,
    required this.tracks,
    this.featuredTracks = const [],
    this.newReleases = const [],
  });

  const Library.empty()
    : artists = const [],
      genres = const [],
      tracks = const [],
      featuredTracks = const [],
      newReleases = const [];

  bool get isEmpty => tracks.isEmpty;

  Artist? artistBySlug(String slug) {
    for (final artist in artists) {
      if (artist.slug == slug) return artist;
    }
    return null;
  }

  Genre? genreBySlug(String slug) {
    for (final genre in genres) {
      if (genre.slug == slug) return genre;
    }
    return null;
  }

  List<Track> tracksForArtist(String slug) => [
    for (final track in tracks)
      if (track.artistSlug == slug) track,
  ];

  List<Track> tracksForGenre(String slug) => [
    for (final track in tracks)
      if (track.genreSlug == slug) track,
  ];

  /// Recherche insensible à la casse et aux accents dans le titre, l'artiste
  /// et le genre. Tous les mots de [query] doivent être présents.
  List<Track> search(String query) {
    final terms = normalizeForSearch(query)
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];

    final results = <Track>[];
    for (final track in tracks) {
      final haystack = normalizeForSearch(
        '${track.title} ${track.artist} ${track.genre}',
      );
      if (terms.every(haystack.contains)) results.add(track);
    }
    return results;
  }
}

/// Minuscules sans accents, pour comparer les recherches.
String normalizeForSearch(String value) {
  const accented = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœ';
  const plain = 'aaaaaaceeeeiiiinooooouuuuyyoe';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = accented.indexOf(char);
    buffer.write(index >= 0 ? plain[index] : char);
  }
  return buffer.toString().trim();
}

/// Résout la clé d'icône stockée dans le seed.
IconData genreIcon(String key) => switch (key) {
  'nature_people' => Icons.nature_people_rounded,
  'album' => Icons.album_rounded,
  'church' => Icons.church_rounded,
  'festival' => Icons.festival_rounded,
  'public' => Icons.public_rounded,
  'waves' => Icons.waves_rounded,
  _ => Icons.graphic_eq_rounded,
};

/// Convertit une couleur `#RRGGBB` ou `#AARRGGBB` en [Color].
Color colorFromHex(String? value, {Color fallback = AppColors.green}) {
  if (value == null) return fallback;
  final hex = value.replaceFirst('#', '').trim();
  if (hex.length != 6 && hex.length != 8) return fallback;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}

class Cover extends StatelessWidget {
  final double size;
  final double radius;
  final String? image;
  final Color tint;

  const Cover({
    super.key,
    this.size = 56,
    this.radius = 12,
    this.image,
    this.tint = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size * dpr).clamp(1, 600).round();
    return ClipRRect(
      borderRadius: border,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Fallback(size: size, radius: radius, tint: tint),
            if (image != null)
              Image.asset(
                image!,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  final double radius;
  final Color tint;

  const _Fallback({
    required this.size,
    required this.radius,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, AppColors.surfaceHigh, 0.45)!,
            Color.lerp(tint, AppColors.bg, 0.82)!,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withAlpha(180),
        size: size * 0.36,
      ),
    );
  }
}
