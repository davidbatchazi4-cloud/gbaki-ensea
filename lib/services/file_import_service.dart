// lib/services/file_import_service.dart — v4 BYTES GARANTIS
// Sur mobile  : lit les bytes depuis le disque si file_picker ne les fournit pas
// Sur web     : bytes fournis directement par file_picker (obligatoire)
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/io_utils.dart';

class ImportedFile {
  final String name;
  final String extension;
  final String? localPath;
  final Uint8List? bytes;
  final String size;

  ImportedFile({
    required this.name,
    required this.extension,
    this.localPath,
    this.bytes,
    required this.size,
  });

  bool get hasData =>
      (bytes != null && bytes!.isNotEmpty) ||
      (localPath != null && localPath!.isNotEmpty);

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class FileImportService {
  static final FileImportService _instance = FileImportService._internal();
  factory FileImportService() => _instance;
  FileImportService._internal();

  static const List<String> _allowedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx',
    'ppt', 'pptx', 'py', 'txt', 'png',
    'jpg', 'jpeg', 'gif', 'zip', 'md', 'csv',
  ];

  /// Import d'un seul fichier
  Future<ImportedFile?> pickSingleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: true,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return null;
      return await _convertWithBytes(result.files.first);
    } catch (_) {
      return null;
    }
  }

  /// Import de plusieurs fichiers
  Future<List<ImportedFile>> pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: true,
        withData: true,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return [];
      final converted = <ImportedFile>[];
      for (final pf in result.files) {
        final f = await _convertWithBytes(pf);
        if (f != null) converted.add(f);
      }
      return converted;
    } catch (_) {
      return [];
    }
  }

  /// Import "dossier entier" = sélection multiple sans filtre d'extension
  Future<List<ImportedFile>> pickFolder() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return [];

      final converted = <ImportedFile>[];
      for (final pf in result.files) {
        if (!_allowedExtensions.contains(_ext(pf.name).toLowerCase())) continue;
        final f = await _convertWithBytes(pf);
        if (f != null) converted.add(f);
      }
      return converted;
    } catch (_) {
      return [];
    }
  }

  // ─── CONVERSION + LECTURE BYTES GARANTIE ────────────────────

  /// Convertit un PlatformFile en ImportedFile en s'assurant que les bytes
  /// sont disponibles (lecture depuis disque si nécessaire sur mobile).
  Future<ImportedFile?> _convertWithBytes(PlatformFile pf) async {
    final ext = _ext(pf.name).toLowerCase();
    if (ext.isEmpty) return null;
    final nameNoExt = _nameNoExt(pf.name);
    final sizeStr = _fmtSize(pf.size);

    Uint8List? bytes = pf.bytes;

    // Sur mobile/desktop : si file_picker n'a pas fourni les bytes,
    // les lire depuis le chemin local (comportement courant sur Android)
    if (!kIsWeb && (bytes == null || bytes.isEmpty) && pf.path != null) {
      bytes = await readFileBytes(pf.path!);
    }

    // Sur web : les bytes sont obligatoires (pas de chemin disponible)
    if (kIsWeb && (bytes == null || bytes.isEmpty)) return null;

    return ImportedFile(
      name: nameNoExt,
      extension: ext,
      localPath: kIsWeb ? null : pf.path,
      bytes: bytes,
      size: sizeStr,
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────

  String _ext(String filename) {
    final dot = filename.lastIndexOf('.');
    return (dot < 0 || dot == filename.length - 1) ? '' : filename.substring(dot + 1);
  }

  String _nameNoExt(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot < 0 ? filename : filename.substring(0, dot);
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Supprimer un fichier local (non-web uniquement)
  Future<void> deleteLocalFile(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return;
    await deleteFile(path);
  }
}
