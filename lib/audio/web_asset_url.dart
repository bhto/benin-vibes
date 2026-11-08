/// URL HTTP d'un asset Flutter servi sur le web.
///
/// `just_audio` charge un asset web en lisant tout le MP3 avec `rootBundle`
/// puis en le convertissant en data URL base64. Pour des fichiers de plusieurs
/// mégaoctets, ce transfert est lent et peut laisser jouer la piste
/// précédente. On sert donc directement l'asset statique : le navigateur le
/// streame et change de source immédiatement.
///
/// Les assets déclarés dans `pubspec.yaml` sont copiés dans le dossier
/// `assets/` du build web. La clé `assets/audio/x.mp3` est donc disponible à
/// l'URL `assets/assets/audio/x.mp3`, relative à la page.
Uri webAssetUrl(String source, {Uri? base}) {
  final key = source.startsWith('assets/') ? source : 'assets/$source';
  return (base ?? Uri.base).resolve('assets/$key');
}
