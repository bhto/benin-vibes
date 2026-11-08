import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data.dart';

/// Résultat de la résolution d'une source audio.
class AudioSource {
  /// URI ou chemin lisible par `just_audio` (asset Flutter ou `file://...`).
  final String uri;

  /// Vrai si le fichier est un asset Flutter compilé (`assets/audio/...`).
  final bool isAsset;

  /// Vrai si le fichier est présent sur l'appareil (asset ou stockage local).
  final bool isLocal;

  const AudioSource({
    required this.uri,
    this.isAsset = false,
    this.isLocal = true,
  });
}

/// Choisit la source audio d'un morceau : le stockage externe de test d'abord
/// (s'il existe), puis l'asset local embarqué dans `assets/audio/`.
class AudioSourceResolver {
  final Future<Directory?> Function() _externalDirectory;
  Directory? _audioDirectory;

  AudioSourceResolver({Future<Directory?> Function()? externalDirectory})
    : _externalDirectory = externalDirectory ?? getExternalStorageDirectory;

  /// Résout [track], ou `null` si aucune source n'est disponible.
  Future<AudioSource?> resolve(Track track) async {
    final local = await _localFile(track);
    if (local != null) {
      return AudioSource(
        uri: Uri.file(local.path).toString(),
        isAsset: false,
        isLocal: true,
      );
    }

    final name = p.basename(track.audioPath);
    if (name.isNotEmpty && name != '.') {
      return AudioSource(
        uri: 'assets/audio/$name',
        isAsset: true,
        isLocal: true,
      );
    }

    return null;
  }

  Future<File?> _localFile(Track track) async {
    final name = p.basename(track.audioPath);
    if (name.isEmpty || name == '.') return null;
    try {
      final directory = _audioDirectory ??= await _resolveAudioDirectory();
      if (directory == null) return null;
      final file = File(p.join(directory.path, name));
      return await file.exists() ? file : null;
    } on Object {
      return null;
    }
  }

  Future<Directory?> _resolveAudioDirectory() async {
    final storage = await _externalDirectory();
    if (storage == null) return null;
    return Directory(p.join(storage.path, 'audio'));
  }
}
