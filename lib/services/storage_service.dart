// lib/services/storage_service.dart — v3 avec fichiers persistants
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'file_storage_service.dart';

class StorageService {
  static const String _boxName = 'gbaki_ensea_v2';
  static const String _uesKey = 'ues';
  static const String _documentsKey = 'documents';
  static const String _roleKey = 'user_role';
  static const String _lastUpdateKey = 'last_update';
  static const String _syncDataKey = 'sync_export';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box _box;
  final FileStorageService _files = FileStorageService();

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    await _files.init();
  }

  // ─── RÔLE ──────────────────────────────────────────────────
  UserRole getRole() {
    final val = _box.get(_roleKey, defaultValue: 'user') as String;
    return val == 'admin' ? UserRole.admin : UserRole.user;
  }

  Future<void> saveRole(UserRole role) async {
    await _box.put(_roleKey, role == UserRole.admin ? 'admin' : 'user');
  }

  // ─── UEs ───────────────────────────────────────────────────
  List<UE> loadUEs() {
    final raw = _box.get(_uesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((e) => UE.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUEs(List<UE> ues) async {
    final json = jsonEncode(ues.map((u) => u.toJson()).toList());
    await _box.put(_uesKey, json);
    await _updateTimestamp();
  }

  // ─── DOCUMENTS ─────────────────────────────────────────────
  List<Document> loadDocuments() {
    final raw = _box.get(_documentsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((e) => Document.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDocuments(List<Document> docs) async {
    final json = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _box.put(_documentsKey, json);
    await _updateTimestamp();
  }

  // ─── FICHIERS BINAIRES ─────────────────────────────────────
  Future<void> saveFileBytes(String docId, Uint8List bytes) async {
    await _files.saveFileBytes(docId, bytes);
  }

  Uint8List? getFileBytes(String docId) => _files.getFileBytes(docId);

  bool hasFileBytes(String docId) => _files.hasFileBytes(docId);

  Future<void> deleteFileBytes(String docId) async {
    await _files.deleteFileBytes(docId);
  }

  // ─── SYNCHRONISATION ───────────────────────────────────────

  /// Génère un code de sync et retourne les données exportées (JSON)
  Future<String> generateSyncExport() async {
    final ues = _box.get(_uesKey) as String? ?? '[]';
    final docs = _box.get(_documentsKey) as String? ?? '[]';
    final files = _files.exportAllForSync();

    final export = {
      'version': 3,
      'timestamp': DateTime.now().toIso8601String(),
      'ues': ues,
      'documents': docs,
      'files': files,
    };

    final exportJson = jsonEncode(export);
    // Stocker localement pour permettre un re-export
    await _box.put(_syncDataKey, exportJson);
    return exportJson;
  }

  /// Importe des données depuis une synchronisation
  Future<bool> importFromSync(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;

      if (version < 2) return false;

      // Importer UEs
      if (data['ues'] != null) {
        await _box.put(_uesKey, data['ues'] as String);
      }

      // Importer Documents
      if (data['documents'] != null) {
        await _box.put(_documentsKey, data['documents'] as String);
      }

      // Importer fichiers binaires
      if (data['files'] != null) {
        final filesData = (data['files'] as Map).cast<String, String>();
        await _files.importFromSync(filesData);
      }

      await _box.put(_lastUpdateKey, DateTime.now().toIso8601String());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── TIMESTAMP ─────────────────────────────────────────────
  Future<void> _updateTimestamp() async {
    await _box.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  String? getLastUpdate() => _box.get(_lastUpdateKey) as String?;

  Future<void> clearAll() async => await _box.clear();
}
