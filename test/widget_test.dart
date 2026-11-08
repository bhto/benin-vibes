// Smoke tests de l'application : onboarding, accueil, artistes et lecteur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/audio/audio_source_resolver.dart';
import 'package:benin_vibes/data.dart';
import 'package:benin_vibes/genre_page.dart';
import 'package:benin_vibes/home_shell.dart';
import 'package:benin_vibes/main.dart';
import 'package:benin_vibes/now_playing_sheet.dart';
import 'package:benin_vibes/player_controller.dart';
import 'package:benin_vibes/theme.dart';

import 'support/fake_audio_engine.dart';
import 'support/library_fixture.dart';

Widget buildTestApp() {
  return BeninVibesApp(
    library: buildTestLibrary(),
    audioEngine: FakeAudioEngine(),
    audioResolver: AudioSourceResolver(externalDirectory: () async => null),
  );
}

Future<void> openHome(WidgetTester tester) async {
  await tester.pumpWidget(buildTestApp());
  await tester.pump();
  await tester.tap(find.text('Passer'));
  await tester.pumpAndSettle();
}

/// Le salut dépend de l'heure : on vérifie qu'il fait partie des variantes.
final Finder greetingFinder = find.textContaining(
  RegExp(r'^(Bonjour|Bon après-midi|Bonsoir|Bonne nuit)'),
);

/// Choisit le mix pour démarrer une lecture, comme le ferait l'utilisateur.
Future<void> startMix(WidgetTester tester) async {
  await tester.tap(find.text('Mix Bénin'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('L\'onboarding mène à l\'accueil sans mini-lecteur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('Le son du Bénin dans ta poche'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(greetingFinder, findsOneWidget);
    expect(find.text('Accueil'), findsWidgets);
    expect(find.byType(MiniPlayer), findsNothing);
  });

  testWidgets('Le mini-lecteur apparaît après le choix d\'un morceau', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    expect(find.byType(MiniPlayer), findsNothing);
    await startMix(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('EN LECTURE'), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsWidgets);
  });

  testWidgets('Un artiste ouvre sa liste sans lancer la lecture', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    await tester.scrollUntilVisible(
      find.text('Artistes populaires'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(HomePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessimè').last);
    await tester.pumpAndSettle();

    expect(find.text('ARTISTE'), findsOneWidget);
    expect(find.text('1 morceau disponible'), findsOneWidget);
    expect(find.byType(MiniPlayer), findsNothing);

    await tester.tap(find.text('Zinli Night'));
    await tester.pumpAndSettle();

    expect(greetingFinder, findsOneWidget);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('Le header suit le menu avec une transition animée', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    expect(find.byKey(const ValueKey('header-title-0')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pump();
    // Pendant la transition, les deux titres cohabitent brièvement.
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-title-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('header-title-0')), findsNothing);

    await tester.tap(find.byIcon(Icons.library_music_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-title-2')), findsOneWidget);
    expect(greetingFinder, findsOneWidget);
  });

  testWidgets(
    'Un genre ouvre ses morceaux et « Tout lire » lance la catégorie',
    (WidgetTester tester) async {
      await openHome(tester);

      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Artistes à suivre'), findsNothing);

      await tester.tap(find.text('Afropop'));
      await tester.pumpAndSettle();

      expect(find.text('GENRE'), findsOneWidget);
      expect(find.text('2 morceaux disponibles'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GenrePage),
          matching: find.text('Zinli Night'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GenrePage),
          matching: find.text('Cotonou Vibes'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Tout lire'));
      await tester.pumpAndSettle();

      expect(find.byType(GenrePage), findsNothing);
      expect(find.byType(MiniPlayer), findsOneWidget);
    },
  );

  testWidgets('La recherche filtre les titres sans quitter la vue', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zinli');
    await tester.pumpAndSettle();

    expect(find.text('1 titre trouvé'), findsOneWidget);
    final result = find.descendant(
      of: find.byType(DiscoverPage),
      matching: find.text('Zinli Night'),
    );
    expect(result, findsOneWidget);

    await tester.tap(result);
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.text('1 titre trouvé'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'zinli');
  });

  testWidgets('Sans résultat, des suggestions lancent la musique', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();

    expect(find.text('Aucun titre trouvé'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);

    final suggestion = find.descendant(
      of: find.byType(DiscoverPage),
      matching: find.text('Zinli Night'),
    );
    expect(suggestion, findsOneWidget);

    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.text('Aucun titre trouvé'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'zzzzzz');
  });

  testWidgets('La bibliothèque propose Titres, Favoris et Artistes', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    await tester.tap(find.byIcon(Icons.library_music_outlined));
    await tester.pumpAndSettle();

    final library = find.byType(LibraryPage);
    expect(find.text('Titres'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Artistes'), findsOneWidget);
    expect(
      find.descendant(
        of: library,
        matching: find.byIcon(Icons.more_horiz_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: library, matching: find.text('Zinli Night')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: library, matching: find.text('Cotonou Vibes')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: library, matching: find.text('Gbè Mi')),
      findsOneWidget,
    );

    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun favori'), findsOneWidget);
    expect(
      find.text('Les titres que tu aimes apparaîtront ici.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Artistes'));
    await tester.pumpAndSettle();
    for (final name in ['Sessimè', 'Fanicko', 'Zeynab']) {
      expect(
        find.descendant(of: library, matching: find.text(name)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: library, matching: find.text('1 titre')),
      findsNWidgets(3),
    );
  });

  testWidgets('La cloche ouvre le message de bienvenue', (
    WidgetTester tester,
  ) async {
    await openHome(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('1 message'), findsOneWidget);
    expect(find.text('Bienvenue sur Benin Vibes 👋'), findsOneWidget);

    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur Benin Vibes 👋'), findsNothing);
  });

  testWidgets('Le cœur alimente l\'onglet Favoris de la bibliothèque', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.library_music_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(LibraryPage),
        matching: find.text('Zinli Night'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Le shuffle et la répétition s\'activent dans le lecteur', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Lecture aléatoire'), findsOneWidget);
    await tester.tap(find.byTooltip('Lecture aléatoire'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Désactiver la lecture aléatoire'), findsOneWidget);

    expect(find.byTooltip('Répéter la file'), findsOneWidget);
    await tester.tap(find.byTooltip('Répéter la file'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Désactiver la répétition'), findsOneWidget);
  });

  testWidgets('Le titre du lecteur reste centré avec ou sans paroles', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    final sheet = find.byType(NowPlayingSheet);
    final center = tester.getCenter(sheet).dx;
    final title = find.descendant(of: sheet, matching: find.text('EN LECTURE'));

    // Zinli Night possède des paroles : 4 éléments dans l'en-tête.
    expect(find.byTooltip('Afficher les paroles'), findsOneWidget);
    expect(tester.getCenter(title).dx, closeTo(center, 1));

    await tester.tap(
      find.descendant(
        of: sheet,
        matching: find.byIcon(Icons.skip_next_rounded),
      ),
    );
    await tester.pumpAndSettle();

    // Cotonou Vibes n'a pas de paroles : 3 éléments dans l'en-tête.
    expect(find.byTooltip('Afficher les paroles'), findsNothing);
    expect(tester.getCenter(title).dx, closeTo(center, 1));
  });

  testWidgets('Les paroles s\'ouvrent depuis le lecteur', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Afficher les paroles'));
    await tester.pumpAndSettle();

    expect(find.text('PAROLES'), findsOneWidget);
    expect(find.text('La nuit tombe sur Cotonou'), findsOneWidget);
    expect(find.text('Zinli Night'), findsWidgets);
  });

  testWidgets('Le défilement manuel met les paroles en pause', (
    WidgetTester tester,
  ) async {
    final track = Track(
      id: 'paroles_longues',
      title: 'Paroles longues',
      artist: 'Artiste test',
      artistSlug: 'artiste_test',
      genre: 'Afropop',
      genreSlug: 'afropop',
      audioPath: 'audio/paroles_longues.mp3',
      duration: const Duration(minutes: 4),
      lyrics: [
        for (var i = 0; i < 40; i++)
          LyricLine(Duration(seconds: i * 5), 'Ligne de paroles $i'),
      ],
    );
    final player = PlayerController(tracks: [track]);
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showNowPlaying(context, player),
              child: const Text('Ouvrir le lecteur'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir le lecteur'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Afficher les paroles'));
    await tester.pumpAndSettle();

    expect(find.text('Revenir aux paroles'), findsNothing);

    final lyrics = find.descendant(
      of: find.byType(NowPlayingSheet),
      matching: find.byType(SingleChildScrollView),
    );
    // Défilement important : la ligne chantée sort largement du viewport.
    for (var i = 0; i < 5; i++) {
      await tester.drag(lyrics, const Offset(0, -240));
      await tester.pumpAndSettle();
    }

    expect(find.text('Revenir aux paroles'), findsOneWidget);

    await tester.tap(find.text('Revenir aux paroles'));
    await tester.pumpAndSettle();

    expect(find.text('Revenir aux paroles'), findsNothing);

    // La ligne en cours est revenue dans la zone visible, même après un
    // décalage important.
    final viewport = tester.getRect(lyrics);
    final activeLine = tester.getRect(find.text('Ligne de paroles 0'));
    expect(activeLine.top, greaterThanOrEqualTo(viewport.top - 1));
    expect(activeLine.bottom, lessThanOrEqualTo(viewport.bottom + 1));
  });

  testWidgets('Le bouton paroles est masqué sans lyrics', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('Paroles'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NowPlayingSheet),
        matching: find.byIcon(Icons.skip_next_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cotonou Vibes'), findsWidgets);
    expect(find.byTooltip('Afficher les paroles'), findsNothing);
    expect(find.text('Paroles'), findsNothing);
  });

  testWidgets('La file d\'attente s\'ouvre depuis le lecteur', (
    WidgetTester tester,
  ) async {
    await openHome(tester);
    await startMix(tester);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip("Afficher la file d'attente"));
    await tester.pumpAndSettle();

    expect(find.text("FILE D'ATTENTE"), findsOneWidget);
    expect(find.text('À SUIVRE'), findsOneWidget);
    expect(find.text('EN LECTURE'), findsOneWidget);
    expect(find.text('Cotonou Vibes'), findsWidgets);
  });
}
