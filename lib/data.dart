import 'package:flutter/material.dart';
import 'theme.dart';

class Track {
  final String title;
  final String artist;
  final String? image;
  const Track(this.title, this.artist, {this.image});
}

// Données de démo : à remplacer par ton backend / tes vrais titres.
const demoTracks = [
  Track('Zinli Night', 'Sessimè', image: 'assets/artists/sessime.jpg'),
  Track('Cotonou Vibes', 'Fanicko', image: 'assets/artists/fanicko.jpg'),
  Track('Gbè Mi', 'Zeynab', image: 'assets/artists/zeynab.jpg'),
  Track('Ouidah Soul', 'Angélique Kidjo', image: 'assets/artists/angelique_kidjo.jpg'),
  Track('Vodoun Groove', 'Gnonnas Pedro'),
  Track('Tchink Fever', 'Dibi Dobo', image: 'assets/artists/dibi_dobo.jpg'),
];

const genres = [
  'Zinli',
  'Afrobeat',
  'Gospel',
  'Vodoun Jazz',
  'Tchink System',
  'Rumba',
  'Highlife',
  'Hip-hop',
];

const genreColors = [
  Color(0xFF2FB36D),
  Color(0xFFE8112D),
  Color(0xFF6A4CFF),
  Color(0xFF00A3A3),
  Color(0xFFFF7A1A),
  Color(0xFFB8860B),
  Color(0xFF2E7D32),
  Color(0xFFAD1457),
];

class Cover extends StatelessWidget {
  final double size;
  final double radius;
  final String? image;
  const Cover({super.key, this.size = 56, this.radius = 12, this.image});

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
        child: image == null
            ? _Fallback(size: size, radius: radius)
            : Image.asset(
                image!,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                errorBuilder: (_, _, _) => _Fallback(size: size, radius: radius),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  final double radius;
  const _Fallback({required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.surface,
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.green.withAlpha(170),
        size: size * 0.4,
      ),
    );
  }
}
