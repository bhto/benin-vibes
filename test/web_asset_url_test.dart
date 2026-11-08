import 'package:flutter_test/flutter_test.dart';

import 'package:benin_vibes/audio/web_asset_url.dart';

void main() {
  test('sert un asset sous assets/assets, relatif à la racine', () {
    expect(
      webAssetUrl(
        'assets/audio/zinli_night.mp3',
        base: Uri.parse('http://localhost:8080/'),
      ).toString(),
      'http://localhost:8080/assets/assets/audio/zinli_night.mp3',
    );
  });

  test('respecte un sous-dossier de déploiement', () {
    expect(
      webAssetUrl(
        'assets/audio/zinli_night.mp3',
        base: Uri.parse('https://exemple.test/benin-vibes/'),
      ).toString(),
      'https://exemple.test/benin-vibes/assets/assets/audio/zinli_night.mp3',
    );
  });

  test('accepte une clé sans préfixe assets/', () {
    expect(
      webAssetUrl(
        'audio/zinli_night.mp3',
        base: Uri.parse('http://localhost:8080/'),
      ).toString(),
      'http://localhost:8080/assets/assets/audio/zinli_night.mp3',
    );
  });

  test('part du dossier de la page quand elle est nommée', () {
    expect(
      webAssetUrl(
        'assets/audio/zinli_night.mp3',
        base: Uri.parse('http://localhost:8080/index.html'),
      ).toString(),
      'http://localhost:8080/assets/assets/audio/zinli_night.mp3',
    );
  });
}
