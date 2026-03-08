// lib/services/file_reader_service.dart
// Lecture de fichiers locale — uniquement sur mobile/desktop (non-web)
// Ce fichier utilise dart:io — jamais importé sur le web
import 'dart:io';
import 'dart:typed_data';

/// Lit les bytes d'un fichier à partir de son chemin local.
/// Ne pas appeler sur le web (vérifier kIsWeb avant).
Future<Uint8List?> readLocalFileBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Ouvre un fichier avec l'application système associée.
/// Retourne true si réussi.
Future<bool> openFileWithSystem(String path) async {
  try {
    final file = File(path);
    return await file.exists();
  } catch (_) {
    return false;
  }
}
