// lib/providers/app_provider.dart — v5 Firebase Cloud + Hive fallback
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/app_data.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/file_import_service.dart';
import '../utils/io_utils.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _local = StorageService();
  final FirebaseService _firebase = FirebaseService();
  final GeminiService _gemini = GeminiService();
  final FileImportService _fileImport = FileImportService();

  // ─── STATE ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;
  bool _firebaseEnabled = false;

  UserRole _role = UserRole.user;

  List<Filiere> _filieres = [];
  List<UE> _ues = [];
  List<Document> _documents = [];

  // Recherche
  String _searchQuery = '';
  List<Document> _searchResults = [];
  bool _isSearching = false;

  // Upload en cours
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // ─── GETTERS ───────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;
  UserRole get role => _role;
  bool get isAdmin => _role == UserRole.admin;
  bool get firebaseEnabled => _firebaseEnabled;
  List<Filiere> get filieres => _filieres;
  List<UE> get allUEs => _ues;
  List<Document> get allDocuments => _documents;
  List<Document> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  // ─── INIT ──────────────────────────────────────────────────
  Future<void> init() async {
    // 1. Initialiser le stockage local (toujours)
    await _local.init();
    _filieres = List.from(AppData.filieres);
    _role = _local.getRole();

    // 2. Charger depuis Firebase si disponible
    _firebaseEnabled = _firebase.isConfigured;

    if (_firebaseEnabled) {
      try {
        // Charger depuis le cloud
        final cloudUEs = await _firebase.loadUEs();
        final cloudDocs = await _firebase.loadDocuments();

        if (cloudUEs.isNotEmpty || cloudDocs.isNotEmpty) {
          _ues = cloudUEs;
          _documents = cloudDocs;
          // Sauvegarder en local pour offline
          await _local.saveUEs(_ues);
          await _local.saveDocuments(_documents);
        } else {
          // Pas de données cloud → charger local (migration)
          _ues = _local.loadUEs();
          _documents = _local.loadDocuments();
          // Si données locales existent, les uploader vers cloud
          if (_ues.isNotEmpty && isAdmin) {
            await _firebase.saveAllUEs(_ues);
          }
        }
      } catch (e) {
        // Fallback silencieux sur local
        _ues = _local.loadUEs();
        _documents = _local.loadDocuments();
        if (kDebugMode) debugPrint('Fallback local: $e');
      }
    } else {
      // Mode local uniquement
      _ues = _local.loadUEs();
      _documents = _local.loadDocuments();
    }

    _initialized = true;
    notifyListeners();
  }

  /// Recharge les données depuis Firebase (pull-to-refresh)
  Future<void> refreshFromCloud() async {
    if (!_firebaseEnabled) return;
    _isLoading = true;
    notifyListeners();
    try {
      _ues = await _firebase.loadUEs();
      _documents = await _firebase.loadDocuments();
      // Mettre à jour le cache local
      await _local.saveUEs(_ues);
      await _local.saveDocuments(_documents);
    } catch (e) {
      if (kDebugMode) debugPrint('Refresh échoué: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── AUTHENTIFICATION ──────────────────────────────────────
  static const String _adminPassword = 'gbaki@ensea2024';

  Future<bool> loginAdmin(String password) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));

    if (password == _adminPassword) {
      _role = UserRole.admin;
      await _local.saveRole(UserRole.admin);
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void loginUser() {
    _role = UserRole.user;
    _local.saveRole(UserRole.user);
    notifyListeners();
  }

  Future<void> logout() async {
    _role = UserRole.user;
    await _local.saveRole(UserRole.user);
    notifyListeners();
  }

  // ─── FILIÈRES ──────────────────────────────────────────────
  Filiere? getFiliereById(String id) {
    try { return _filieres.firstWhere((f) => f.id == id); }
    catch (_) { return null; }
  }

  Niveau? getNiveauById(String filiereId, String niveauId) {
    return getFiliereById(filiereId)?.niveaux
        .where((n) => n.id == niveauId)
        .firstOrNull;
  }

  // ─── UEs ───────────────────────────────────────────────────
  List<UE> getUEsForSemestre(String niveauId, String semestreId) {
    return _ues.where((u) => u.niveauId == niveauId && u.semestreId == semestreId).toList();
  }

  Future<void> addUE(UE ue) async {
    _ues.add(ue);
    await _local.saveUEs(_ues);
    if (_firebaseEnabled) await _firebase.saveUE(ue);
    notifyListeners();
  }

  Future<void> updateUE(UE updated) async {
    final idx = _ues.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _ues[idx] = updated;
      await _local.saveUEs(_ues);
      if (_firebaseEnabled) await _firebase.saveUE(updated);
      notifyListeners();
    }
  }

  Future<void> deleteUE(String ueId) async {
    for (final doc in _documents.where((d) => d.ueId == ueId)) {
      await _local.deleteFileBytes(doc.id);
      if (_firebaseEnabled) await _firebase.deleteFile(doc.id);
    }
    _ues.removeWhere((u) => u.id == ueId);
    _documents.removeWhere((d) => d.ueId == ueId);
    await _local.saveUEs(_ues);
    await _local.saveDocuments(_documents);
    if (_firebaseEnabled) await _firebase.deleteUE(ueId);
    notifyListeners();
  }

  // ─── MATIÈRES ──────────────────────────────────────────────
  Future<void> addMatiere(String ueId, Matiere matiere) async {
    final ue = _ues.firstWhere((u) => u.id == ueId);
    ue.matieres = [...ue.matieres, matiere];
    await _local.saveUEs(_ues);
    if (_firebaseEnabled) await _firebase.saveUE(ue);
    notifyListeners();
  }

  Future<void> deleteMatiere(String ueId, String matiereId) async {
    final ue = _ues.firstWhere((u) => u.id == ueId);
    ue.matieres = ue.matieres.where((m) => m.id != matiereId).toList();
    for (final doc in _documents.where((d) => d.matiereId == matiereId)) {
      await _local.deleteFileBytes(doc.id);
      if (_firebaseEnabled) await _firebase.deleteFile(doc.id);
    }
    _documents.removeWhere((d) => d.matiereId == matiereId);
    await _local.saveUEs(_ues);
    await _local.saveDocuments(_documents);
    if (_firebaseEnabled) await _firebase.saveUE(ue);
    notifyListeners();
  }

  // ─── DOCUMENTS ─────────────────────────────────────────────
  List<Document> getDocumentsForMatiere(String matiereId, TypeDocument type) {
    return _documents.where((d) => d.matiereId == matiereId && d.type == type).toList();
  }

  List<Document> getDocumentsForNiveau(String niveauId) {
    return _documents.where((d) => d.niveauId == niveauId).toList();
  }

  /// Ajoute un document avec upload Firebase Storage si disponible
  Future<void> addDocument(Document doc, {Uint8List? bytes}) async {
    String? finalUrl = doc.url;

    // Upload vers Firebase Storage si disponible et bytes fournis
    if (_firebaseEnabled && bytes != null && bytes.isNotEmpty) {
      _setUploadState(true, 0.0, 'Upload vers le cloud…');

      final storageUrl = await _firebase.uploadFile(
        docId: doc.id,
        bytes: bytes,
        extension: doc.extension,
        fileName: doc.titre,
        onProgress: (p) {
          _setUploadState(true, p, 'Upload ${(p * 100).toInt()}%…');
        },
      );

      _setUploadState(false, 1.0, '');

      if (storageUrl != null) {
        finalUrl = storageUrl;
        // Sauvegarder aussi en cache local pour offline
        await _local.saveFileBytes(doc.id, bytes);
      }
    } else if (bytes != null && bytes.isNotEmpty) {
      // Mode local uniquement
      await _local.saveFileBytes(doc.id, bytes);
    }

    // Créer le document avec l'URL Firebase Storage
    final finalDoc = Document(
      id: doc.id,
      titre: doc.titre,
      description: doc.description,
      type: doc.type,
      localPath: _firebaseEnabled ? null : doc.localPath,
      url: finalUrl,
      extension: doc.extension,
      taille: doc.taille,
      dateAjout: doc.dateAjout,
      matiereId: doc.matiereId,
      matiereName: doc.matiereName,
      ueId: doc.ueId,
      filiereId: doc.filiereId,
      niveauId: doc.niveauId,
      semestreId: doc.semestreId,
    );

    _documents.add(finalDoc);
    await _local.saveDocuments(_documents);
    if (_firebaseEnabled) await _firebase.saveDocument(finalDoc);
    notifyListeners();
  }

  /// Ajoute plusieurs documents avec upload Firebase Storage
  Future<void> addDocuments(List<Document> docs,
      {Map<String, Uint8List>? bytesMap}) async {

    final finalDocs = <Document>[];

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      Uint8List? bytes = bytesMap?[doc.id];

      // Sur mobile : si bytes non fournis mais localPath disponible
      if ((bytes == null || bytes.isEmpty) && !kIsWeb && doc.hasLocalFile) {
        bytes = await readFileBytes(doc.localPath!);
      }

      String? finalUrl = doc.url;

      // Upload vers Firebase Storage
      if (_firebaseEnabled && bytes != null && bytes.isNotEmpty) {
        _setUploadState(true, i / docs.length,
            'Upload ${i + 1}/${docs.length} : ${doc.titre}…');

        final storageUrl = await _firebase.uploadFile(
          docId: doc.id,
          bytes: bytes,
          extension: doc.extension,
          fileName: doc.titre,
          onProgress: (p) {
            final total = (i + p) / docs.length;
            _setUploadState(true, total,
                'Upload ${i + 1}/${docs.length} : ${(p * 100).toInt()}%…');
          },
        );

        if (storageUrl != null) {
          finalUrl = storageUrl;
          await _local.saveFileBytes(doc.id, bytes);
        }
      } else if (bytes != null && bytes.isNotEmpty) {
        await _local.saveFileBytes(doc.id, bytes);
      }

      finalDocs.add(Document(
        id: doc.id,
        titre: doc.titre,
        description: doc.description,
        type: doc.type,
        localPath: _firebaseEnabled ? null : doc.localPath,
        url: finalUrl,
        extension: doc.extension,
        taille: doc.taille,
        dateAjout: doc.dateAjout,
        matiereId: doc.matiereId,
        matiereName: doc.matiereName,
        ueId: doc.ueId,
        filiereId: doc.filiereId,
        niveauId: doc.niveauId,
        semestreId: doc.semestreId,
      ));
    }

    _setUploadState(false, 1.0, '');
    _documents.addAll(finalDocs);
    await _local.saveDocuments(_documents);

    if (_firebaseEnabled) {
      for (final doc in finalDocs) {
        await _firebase.saveDocument(doc);
      }
    }
    notifyListeners();
  }

  Future<void> deleteDocument(String docId) async {
    await _local.deleteFileBytes(docId);
    final doc = _documents.firstWhere((d) => d.id == docId,
        orElse: () => Document(
            id: '', titre: '', type: TypeDocument.cours, extension: '',
            matiereId: '', matiereName: '', ueId: '',
            filiereId: '', niveauId: '', semestreId: ''));
    if (doc.id.isNotEmpty && doc.hasLocalFile && !kIsWeb) {
      await _fileImport.deleteLocalFile(doc.localPath);
    }
    if (_firebaseEnabled) await _firebase.deleteDocument(docId);
    _documents.removeWhere((d) => d.id == docId);
    await _local.saveDocuments(_documents);
    notifyListeners();
  }

  // ─── BYTES FICHIERS ────────────────────────────────────────

  /// Récupère les bytes d'un document (cache Hive en priorité)
  Uint8List? getDocumentBytes(String docId) {
    return _local.getFileBytes(docId);
  }

  /// Vérifie si les bytes sont disponibles localement
  bool hasDocumentBytes(String docId) {
    return _local.hasFileBytes(docId);
  }

  /// Sauvegarde les bytes en cache local
  Future<void> cacheDocumentBytes(String docId, Uint8List bytes) async {
    if (bytes.isNotEmpty) {
      await _local.saveFileBytes(docId, bytes);
    }
  }

  /// Télécharge les bytes depuis Firebase Storage (si pas en cache)
  Future<Uint8List?> fetchDocumentBytes(String docId) async {
    // 1. Cache local
    final cached = _local.getFileBytes(docId);
    if (cached != null && cached.isNotEmpty) return cached;

    // 2. Firebase Storage
    if (_firebaseEnabled) {
      final doc = _documents.firstWhere(
        (d) => d.id == docId,
        orElse: () => Document(
            id: '', titre: '', type: TypeDocument.cours, extension: '',
            matiereId: '', matiereName: '', ueId: '',
            filiereId: '', niveauId: '', semestreId: ''),
      );

      if (doc.id.isEmpty) return null;

      Uint8List? bytes;

      // Essayer depuis l'URL directe si disponible
      if (doc.url != null && doc.url!.startsWith('https://')) {
        bytes = await _firebase.downloadFromUrl(doc.url!);
      }

      // Sinon télécharger via l'ID + extension
      bytes ??= await _firebase.downloadFile(docId, doc.extension);

      // Mettre en cache si téléchargé
      if (bytes != null && bytes.isNotEmpty) {
        await _local.saveFileBytes(docId, bytes);
      }
      return bytes;
    }

    return null;
  }

  // ─── SYNCHRONISATION (legacy — remplacé par Firebase) ──────

  Future<String> generateSyncData() async {
    return await _local.generateSyncExport();
  }

  Future<bool> importSyncData(String jsonData) async {
    final success = await _local.importFromSync(jsonData);
    if (success) {
      _ues = _local.loadUEs();
      _documents = _local.loadDocuments();
      // Si Firebase actif, uploader les données importées
      if (_firebaseEnabled) {
        await _firebase.saveAllUEs(_ues);
        for (final doc in _documents) {
          await _firebase.saveDocument(doc);
        }
      }
      notifyListeners();
    }
    return success;
  }

  // ─── RECHERCHE ─────────────────────────────────────────────
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final q = query.toLowerCase();
    _searchResults = _documents.where((d) {
      return d.titre.toLowerCase().contains(q) ||
          d.matiereName.toLowerCase().contains(q) ||
          d.type.label.toLowerCase().contains(q) ||
          d.extension.toLowerCase().contains(q);
    }).toList();

    if (_searchResults.isEmpty && _documents.isNotEmpty) {
      try {
        _searchResults = await _gemini.searchDocuments(
          query: query,
          allDocuments: _documents,
        );
      } catch (_) {}
    }

    _isSearching = false;
    notifyListeners();
  }

  String? getLastUpdate() => _local.getLastUpdate();

  // ─── HELPERS PRIVÉS ────────────────────────────────────────
  void _setUploadState(bool uploading, double progress, String status) {
    _isUploading = uploading;
    _uploadProgress = progress;
    _uploadStatus = status;
    notifyListeners();
  }
}
