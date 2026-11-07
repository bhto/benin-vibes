import 'package:flutter/material.dart';
import 'theme.dart';

/// Une ligne de paroles horodatée.
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine(this.time, this.text);
}

class Track {
  final String title;
  final String artist;
  final String? image;

  /// Teinte d'ambiance propre à l'artiste, utilisée pour les fonds,
  /// les halos et les pochettes de secours.
  final Color tint;

  /// Paroles synchronisées. Vide si le titre n'en a pas.
  final List<LyricLine> lyrics;

  const Track(
    this.title,
    this.artist, {
    this.image,
    this.tint = AppColors.green,
    this.lyrics = const [],
  });
}

// Les paroles ci-dessous sont des textes de démonstration originaux, écrits
// pour l'app. À remplacer par les paroles officielles, sous licence.

const _zinliNightLyrics = [
  LyricLine(Duration.zero, 'La nuit tombe sur Cotonou'),
  LyricLine(Duration(seconds: 16), 'Les lampions s\'allument, tout le monde est debout'),
  LyricLine(Duration(seconds: 34), 'Zinli dans les haut-parleurs, la piste s\'enflamme'),
  LyricLine(Duration(seconds: 52), 'On oublie la semaine, on danse jusqu\'au matin'),
  LyricLine(Duration(seconds: 72), 'Awǎ, awǎ, le rythme nous appelle'),
  LyricLine(Duration(seconds: 92), 'Frappe dans tes mains, laisse parler ton corps'),
  LyricLine(Duration(seconds: 115), 'Sous les étoiles, on écrit notre histoire'),
  LyricLine(Duration(seconds: 138), 'Zinli night, la ville ne dort pas'),
  LyricLine(Duration(seconds: 162), 'Zinli night, on est bien là'),
  LyricLine(Duration(seconds: 182), 'Un pas, deux pas, le cercle s\'agrandit'),
  LyricLine(Duration(seconds: 202), 'Gardons ce moment, il est à nous'),
  LyricLine(Duration(seconds: 220), 'La nuit s\'achève, le cœur reste chaud'),
];

const _cotonouVibesLyrics = [
  LyricLine(Duration.zero, 'Réveil au son des klaxons'),
  LyricLine(Duration(seconds: 15), 'Le marché s\'anime, les couleurs tourbillonnent'),
  LyricLine(Duration(seconds: 33), 'Zémidjan dans la circulation'),
  LyricLine(Duration(seconds: 52), 'Cotonou vibes, du matin jusqu\'au soir'),
  LyricLine(Duration(seconds: 70), 'Les pieds dans le sable, le cœur en fête'),
  LyricLine(Duration(seconds: 90), 'On avance ensemble, rien ne nous arrête'),
  LyricLine(Duration(seconds: 110), 'Cotonou vibes, la ville respire'),
  LyricLine(Duration(seconds: 132), 'Chaque rue raconte une histoire'),
  LyricLine(Duration(seconds: 153), 'Les enfants courent, les rires s\'envolent'),
  LyricLine(Duration(seconds: 175), 'On construit demain avec nos mains'),
  LyricLine(Duration(seconds: 198), 'Cotonou vibes, encore une fois'),
  LyricLine(Duration(seconds: 218), 'La ville chante, la ville vit'),
];

const _gbeMiLyrics = [
  LyricLine(Duration.zero, 'Gbè mi, écoute ma voix'),
  LyricLine(Duration(seconds: 18), 'Elle s\'élève au-dessus des toits'),
  LyricLine(Duration(seconds: 38), 'Dans le silence, je cherche la lumière'),
  LyricLine(Duration(seconds: 58), 'Chaque prière ouvre une porte'),
  LyricLine(Duration(seconds: 78), 'Gbè mi, ne ferme pas ton cœur'),
  LyricLine(Duration(seconds: 98), 'L\'amour est plus fort que la peur'),
  LyricLine(Duration(seconds: 120), 'Marche avec moi sur ce chemin'),
  LyricLine(Duration(seconds: 142), 'Nous ne sommes jamais seuls'),
  LyricLine(Duration(seconds: 165), 'Gbè mi, la voix de nos mères'),
  LyricLine(Duration(seconds: 185), 'Elle nous guide, elle nous relève'),
  LyricLine(Duration(seconds: 205), 'Chante encore, même dans la nuit'),
  LyricLine(Duration(seconds: 222), 'La lumière finit toujours par venir'),
];

const _ouidahSoulLyrics = [
  LyricLine(Duration.zero, 'Le vent vient de l\'Atlantique'),
  LyricLine(Duration(seconds: 17), 'Il porte les mémoires de Ouidah'),
  LyricLine(Duration(seconds: 36), 'Sur le sable, les pas des ancêtres'),
  LyricLine(Duration(seconds: 56), 'La porte du non-retour se souvient'),
  LyricLine(Duration(seconds: 76), 'Ouidah soul, racines profondes'),
  LyricLine(Duration(seconds: 97), 'Nous dansons pour ceux qui sont partis'),
  LyricLine(Duration(seconds: 118), 'Tambours et chœurs, même souffle'),
  LyricLine(Duration(seconds: 140), 'La mer répond à nos chants'),
  LyricLine(Duration(seconds: 162), 'Ouidah soul, la dignité debout'),
  LyricLine(Duration(seconds: 182), 'Nos enfants connaîtront l\'histoire'),
  LyricLine(Duration(seconds: 202), 'Le passé éclaire notre avenir'),
  LyricLine(Duration(seconds: 220), 'Le vent ne cesse jamais de souffler'),
];

const _vodounGrooveLyrics = [
  LyricLine(Duration.zero, 'Les tambours appellent la terre'),
  LyricLine(Duration(seconds: 18), 'Le rythme monte, le sol vibre'),
  LyricLine(Duration(seconds: 38), 'Vodoun groove, héritage vivant'),
  LyricLine(Duration(seconds: 58), 'Les ancêtres dansent avec nous'),
  LyricLine(Duration(seconds: 78), 'Le cercle est ouvert'),
  LyricLine(Duration(seconds: 98), 'Laisse ton corps suivre le tambour'),
  LyricLine(Duration(seconds: 118), 'Vodoun groove, force et sagesse'),
  LyricLine(Duration(seconds: 138), 'Chaque battement raconte un monde'),
  LyricLine(Duration(seconds: 160), 'Le groove ne s\'arrête jamais'),
  LyricLine(Duration(seconds: 180), 'Passe le rythme à la génération'),
  LyricLine(Duration(seconds: 200), 'Vodoun groove, debout, ensemble'),
  LyricLine(Duration(seconds: 220), 'La terre écoute, le ciel répond'),
];

const _tchinkFeverLyrics = [
  LyricLine(Duration.zero, 'Batterie tchink dans la nuit'),
  LyricLine(Duration(seconds: 16), 'Le rythme claque, tout le monde suit'),
  LyricLine(Duration(seconds: 34), 'Frappe, frappe, le son s\'envole'),
  LyricLine(Duration(seconds: 52), 'Tchink fever, la fièvre monte'),
  LyricLine(Duration(seconds: 72), 'Tambour tendu, mains rapides'),
  LyricLine(Duration(seconds: 92), 'On danse serré, on chante fort'),
  LyricLine(Duration(seconds: 112), 'Tchink fever, rien ne nous arrête'),
  LyricLine(Duration(seconds: 134), 'Les pieds frappent la terre en cœur'),
  LyricLine(Duration(seconds: 156), 'Le système tchink ne s\'éteint pas'),
  LyricLine(Duration(seconds: 178), 'Passe le beat à la nouvelle génération'),
  LyricLine(Duration(seconds: 200), 'Tchink fever, encore plus fort'),
  LyricLine(Duration(seconds: 220), 'Le silence attendra demain'),
];

// Données de démo : à remplacer par ton backend / tes vrais titres.
const demoTracks = [
  Track(
    'Zinli Night',
    'Sessimè',
    image: 'assets/artists/sessime.jpg',
    tint: Color(0xFFE0447C),
    lyrics: _zinliNightLyrics,
  ),
  Track(
    'Cotonou Vibes',
    'Fanicko',
    image: 'assets/artists/fanicko.jpg',
    tint: Color(0xFF4E77B8),
    lyrics: _cotonouVibesLyrics,
  ),
  Track(
    'Gbè Mi',
    'Zeynab',
    image: 'assets/artists/zeynab.jpg',
    tint: Color(0xFF8B5CF6),
    lyrics: _gbeMiLyrics,
  ),
  Track(
    'Ouidah Soul',
    'Angélique Kidjo',
    image: 'assets/artists/angelique_kidjo.jpg',
    tint: Color(0xFFE8833A),
    lyrics: _ouidahSoulLyrics,
  ),
  Track(
    'Vodoun Groove',
    'Gnonnas Pedro',
    tint: AppColors.green,
    lyrics: _vodounGrooveLyrics,
  ),
  Track(
    'Tchink Fever',
    'Dibi Dobo',
    image: 'assets/artists/dibi_dobo.jpg',
    tint: Color(0xFFD93A4A),
    lyrics: _tchinkFeverLyrics,
  ),
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
  Color(0xFFE0447C),
  Color(0xFF6A4CFF),
  Color(0xFF00A3A3),
  Color(0xFFE8833A),
  Color(0xFFB8860B),
  Color(0xFF2E7D32),
  Color(0xFFAD1457),
];

const genreIcons = [
  Icons.graphic_eq_rounded,
  Icons.album_rounded,
  Icons.church_rounded,
  Icons.auto_awesome_rounded,
  Icons.waves_rounded,
  Icons.nightlife_rounded,
  Icons.festival_rounded,
  Icons.headphones_rounded,
];

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
