import 'package:flutter_test/flutter_test.dart';

import 'support/library_fixture.dart';

void main() {
  final library = buildTestLibrary();

  test('la recherche ignore la casse', () {
    expect(library.search('ZINLI').map((track) => track.id), ['zinli_night']);
  });

  test('la recherche ignore les accents', () {
    expect(library.search('sessime').single.id, 'zinli_night');
  });

  test('la recherche couvre aussi le genre', () {
    expect(library.search('gospel').map((track) => track.id), ['gbe_mi']);
  });

  test('tous les mots de la requête doivent correspondre', () {
    expect(library.search('fanicko cotonou').single.id, 'cotonou_vibes');
    expect(library.search('fanicko gospel'), isEmpty);
  });

  test('une requête vide ne renvoie rien', () {
    expect(library.search('   '), isEmpty);
  });
}
