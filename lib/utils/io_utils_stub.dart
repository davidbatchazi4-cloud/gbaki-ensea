// lib/utils/io_utils_stub.dart
// Stub web — toutes les fonctions IO retournent null/false
import 'dart:typed_data';

Future<Uint8List?> readFileBytes(String path) async => null;
Future<void> deleteFile(String path) async {}
Future<bool> fileExistsAtPath(String path) async => false;
