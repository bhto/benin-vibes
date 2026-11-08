import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Mémorise si l'onboarding a déjà été parcouru.
///
/// L'état est conservé dans un petit fichier du dossier de support de
/// l'application : au lancement suivant, l'accueil s'affiche directement.
abstract interface class OnboardingStore {
  /// Vrai si l'utilisateur a déjà terminé ou passé l'onboarding.
  Future<bool> hasCompleted();

  /// Enregistre le passage de l'onboarding.
  Future<void> markCompleted();
}

/// Implémentation par fichier, sans dépendance supplémentaire.
class FileOnboardingStore implements OnboardingStore {
  final Future<Directory> Function() _directory;

  FileOnboardingStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const _fileName = 'onboarding_completed';

  Future<File> _file() async =>
      File(p.join((await _directory()).path, _fileName));

  @override
  Future<bool> hasCompleted() async {
    try {
      return await (await _file()).exists();
    } catch (error) {
      // En cas d'échec, on propose l'onboarding plutôt que de bloquer l'accès.
      return false;
    }
  }

  @override
  Future<void> markCompleted() async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString('1');
    } catch (_) {
      // Le marqueur n'est pas indispensable : au pire, l'onboarding revient.
    }
  }
}
