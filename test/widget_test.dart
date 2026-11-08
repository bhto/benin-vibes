// Smoke tests de l'application : onboarding, accueil, artistes et lecteur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/audio/audio_source_resolver.dart';
import 'package:benin_vibes/genre_page.dart';
import 'package:benin_vibes/home_shell.dart';
import 'package:benin_vibes/main.dart';

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
