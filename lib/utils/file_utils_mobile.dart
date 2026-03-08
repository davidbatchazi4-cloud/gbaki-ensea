// lib/utils/file_utils_mobile.dart
// Implémentation réelle pour mobile/desktop (dart:io disponible)
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

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

Future<String?> writeBytesToTempFile(
    Uint8List bytes, String ext, String docId) async {
  try {
    final dir = await getTemporaryDirectory();
    final fileName = 'gbaki_${docId.hashCode.abs()}.$ext';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  } catch (_) {
    return null;
  }
}

Future<bool> fileExists(String path) async {
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}
