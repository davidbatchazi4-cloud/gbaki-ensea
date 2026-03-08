// lib/services/file_storage_service.dart
// Gestion persistante des fichiers importés en mémoire Hive
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FileStorageService {
  static const String _boxName = 'gbaki_files_v1';

  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  Box? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  Box get _b {
    if (_box == null || !_box!.isOpen) {
      throw StateError('FileStorageService not initialized');
    }
    return _box!;
  }

  /// Sauvegarde les bytes d'un fichier (base64 pour compatibilité Hive)
  Future<void> saveFileBytes(String docId, Uint8List bytes) async {
    await init();
    // Stocker en base64 string pour compatibilité maximale avec Hive
    await _b.put('file_$docId', base64Encode(bytes));
  }

  /// Récupère les bytes d'un fichier par son ID document
  Uint8List? getFileBytes(String docId) {
    if (_box == null || !_box!.isOpen) return null;
    try {
      final val = _b.get('file_$docId');
      if (val == null) return null;
      return base64Decode(val as String);
    } catch (_) {
      return null;
    }
  }

  /// Vérifie la disponibilité des bytes
  bool hasFileBytes(String docId) {
    if (_box == null || !_box!.isOpen) return false;
    return _b.containsKey('file_$docId');
  }

  /// Supprime les bytes d'un fichier
  Future<void> deleteFileBytes(String docId) async {
    await init();
    await _b.delete('file_$docId');
  }

  /// Taille stockée en bytes pour un document
  int getStoredSize(String docId) {
    final bytes = getFileBytes(docId);
    return bytes?.length ?? 0;
  }

  /// Export du contenu pour synchronisation (retourne la map base64)
  Map<String, String> exportAllForSync() {
    if (_box == null || !_box!.isOpen) return {};
    final result = <String, String>{};
    for (final key in _b.keys) {
      final k = key as String;
      if (k.startsWith('file_')) {
        result[k] = _b.get(k) as String;
      }
    }
    return result;
  }

  /// Import depuis une synchronisation
  Future<void> importFromSync(Map<String, String> data) async {
    await init();
    for (final entry in data.entries) {
      await _b.put(entry.key, entry.value);
    }
  }
}
