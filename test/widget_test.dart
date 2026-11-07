// Smoke tests de l'application : onboarding, accueil et vue « en lecture ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/home_shell.dart';
import 'package:benin_vibes/main.dart';

void main() {
  testWidgets('L\'onboarding démarre et mène à l\'accueil', (WidgetTester tester) async {
    await tester.pumpWidget(const BeninVibesApp());
    await tester.pump();

    expect(find.text('Le son du Bénin dans ta poche'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour 👋'), findsOneWidget);
    expect(find.text('Accueil'), findsWidgets);
  });

  testWidgets('Le mini-lecteur ouvre la vue plein écran', (WidgetTester tester) async {
    await tester.pumpWidget(const BeninVibesApp());
    await tester.pump();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('EN LECTURE'), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsWidgets);
  });

  testWidgets('Les paroles s\'ouvrent depuis le lecteur', (WidgetTester tester) async {
    await tester.pumpWidget(const BeninVibesApp());
    await tester.pump();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Afficher les paroles'));
    await tester.pumpAndSettle();

    expect(find.text('PAROLES'), findsOneWidget);
    expect(find.text('La nuit tombe sur Cotonou'), findsOneWidget);
    expect(find.text('Zinli Night'), findsWidgets);
  });

  testWidgets('La file d\'attente s\'ouvre depuis le lecteur',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BeninVibesApp());
    await tester.pump();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

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
