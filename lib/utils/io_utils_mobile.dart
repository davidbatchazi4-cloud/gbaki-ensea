// lib/utils/io_utils_mobile.dart
// Implémentation réelle pour mobile/desktop (dart:io disponible)
import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFileBytes(String path) async {
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

Future<void> deleteFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}

Future<bool> fileExistsAtPath(String path) async {
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}
