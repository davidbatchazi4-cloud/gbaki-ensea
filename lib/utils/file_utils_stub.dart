// lib/utils/file_utils_stub.dart
// Stub pour la plateforme web — toutes les fonctions IO retournent null
import 'dart:typed_data';

Future<Uint8List?> readLocalFileBytes(String path) async => null;

Future<String?> writeBytesToTempFile(
    Uint8List bytes, String ext, String docId) async => null;

Future<bool> fileExists(String path) async => false;
