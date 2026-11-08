import 'dart:async';

/// Sérialise les changements de source audio.
///
/// Un lecteur ne peut charger qu'une source à la fois : si deux chargements
/// se chevauchent, celui qui se termine en dernier peut imposer son morceau
/// alors que l'utilisateur en a déjà choisi un autre. La file exécute donc les
/// chargements dans l'ordre et ignore une demande devenue obsolète avant même
/// de démarrer.
class SourceSwitchQueue {
  int _latest = 0;
  Future<void> _tail = Future<void>.value();

  /// Exécute [load] après le chargement précédent.
  ///
  /// Renvoie `null` quand la demande a été remplacée par une plus récente
  /// avant d'avoir pu démarrer.
  Future<T?> run<T>(Future<T?> Function() load) {
    final request = ++_latest;
    final previous = _tail;
    final result = _run(previous, request, load);
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<T?> _run<T>(
    Future<void> previous,
    int request,
    Future<T?> Function() load,
  ) async {
    try {
      await previous;
    } catch (_) {
      // Un chargement en échec ne doit pas bloquer les suivants.
    }
    if (request != _latest) return null;
    return load();
  }
}
