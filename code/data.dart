import 'package:flutter/material.dart';

class Track {
  final String title;
  final String artist;
  final List<Color> colors;
  const Track(this.title, this.artist, this.colors);
}

// Données de démo : à remplacer par ton backend / tes vrais titres.
const demoTracks = [
  Track('Zinli Night', 'Sessimè', [Color(0xFF2FB36D), Color(0xFF1C8A53)]),
  Track('Cotonou Vibes', 'Fanicko', [Color(0xFFE8112D), Color(0xFFA3303F)]),
  Track('Gbè Mi', 'Zeynab', [Color(0xFFFCD116), Color(0xFFC9A400)]),
  Track('Ouidah Soul', 'Angélique Kidjo', [Color(0xFF6A4CFF), Color(0xFF4B3AB5)]),
  Track('Vodoun Groove', 'Gnonnas Pedro', [Color(0xFF00A3A3), Color(0xFF1F7F7F)]),
  Track('Tchink Fever', 'Dibi Dobo', [Color(0xFFFF7A1A), Color(0xFFB85A14)]),
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
  final List<Color> colors;
  final double size;
  final double radius;
  const Cover({super.key, required this.colors, this.size = 56, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note_rounded, color: Colors.white70, size: size * 0.4),
    );
  }
}
