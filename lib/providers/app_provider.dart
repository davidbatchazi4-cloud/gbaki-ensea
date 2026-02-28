// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/app_data.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GeminiService _gemini = GeminiService();

  // State
  bool _isLoading = false;
  bool _isAdminLogged = false;
  String? _error;
  String _searchQuery = '';
  List<Document> _searchResults = [];
  bool _isSearching = false;

  // Structure data
  List<Filiere> _filieres = [];
  Map<String, List<Document>> _documentsByNiveau = {};
  Map<String, List<UE>> _uesByNiveau = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get isAdminLogged => _isAdminLogged;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<Document> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<Filiere> get filieres => _filieres;
  Map<String, List<Document>> get documentsByNiveau => _documentsByNiveau;
  Map<String, List<UE>> get uesByNiveau => _uesByNiveau;

  Future<void> init() async {
    await _storage.init();
    _filieres = List.from(AppData.filieres);
    _isAdminLogged = await _storage.isAdminLogged();
    _loadStoredData();
    notifyListeners();
  }

  void _loadStoredData() {
    final docData = _storage.loadDocuments();
    if (docData != null) {
      // Charger les documents depuis le stockage local
      // TODO: Parser et intégrer
    }
  }

  // Admin
  Future<bool> loginAdmin(String password) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // Mot de passe admin (à changer en production)
    const adminPassword = 'gbaki@ensea2024';
    if (password == adminPassword) {
      _isAdminLogged = true;
      await _storage.setAdminLogged(true);
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logoutAdmin() async {
    _isAdminLogged = false;
    await _storage.setAdminLogged(false);
    notifyListeners();
  }

  // Filières
  List<Filiere> getFilieres() => _filieres;

  Filiere? getFiliereById(String id) {
    try {
      return _filieres.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  Niveau? getNiveauById(String filiereId, String niveauId) {
    final filiere = getFiliereById(filiereId);
    if (filiere == null) return null;
    try {
      return filiere.niveaux.firstWhere((n) => n.id == niveauId);
    } catch (e) {
      return null;
    }
  }

  // Documents
  List<Document> getDocumentsForNiveau(String niveauId) {
    return _documentsByNiveau[niveauId] ?? [];
  }

  List<UE> getUEsForNiveau(String niveauId) {
    return _uesByNiveau[niveauId] ?? _getDefaultUEs(niveauId);
  }

  List<UE> _getDefaultUEs(String niveauId) {
    // UEs par défaut selon le niveau
    if (niveauId.startsWith('as2')) {
      return [
        UE(id: 'ue1_$niveauId', nom: 'UE1 - Mathématiques', code: 'UE1', matieres: [
          Matiere(id: 'mat1_$niveauId', nom: 'Analyse', cours: [], devoirs: [], td: [], complements: []),
          Matiere(id: 'mat2_$niveauId', nom: 'Algèbre', cours: [], devoirs: [], td: [], complements: []),
        ]),
        UE(id: 'ue2_$niveauId', nom: 'UE2 - Statistiques', code: 'UE2', matieres: [
          Matiere(id: 'mat3_$niveauId', nom: 'Probabilités', cours: [], devoirs: [], td: [], complements: []),
          Matiere(id: 'mat4_$niveauId', nom: 'Statistiques', cours: [], devoirs: [], td: [], complements: []),
        ]),
        UE(id: 'ue3_$niveauId', nom: 'UE3 - Informatique', code: 'UE3', matieres: [
          Matiere(id: 'mat5_$niveauId', nom: 'Python', cours: [], devoirs: [], td: [], complements: []),
          Matiere(id: 'mat6_$niveauId', nom: 'Bases de données', cours: [], devoirs: [], td: [], complements: []),
        ]),
        UE(id: 'ue4_$niveauId', nom: 'UE4 - Économie', code: 'UE4', matieres: [
          Matiere(id: 'mat7_$niveauId', nom: 'Microéconomie', cours: [], devoirs: [], td: [], complements: []),
          Matiere(id: 'mat8_$niveauId', nom: 'Macroéconomie', cours: [], devoirs: [], td: [], complements: []),
        ]),
      ];
    }
    return [
      UE(id: 'ue1_$niveauId', nom: 'UE1 - Fondamentaux', code: 'UE1', matieres: [
        Matiere(id: 'mat1_$niveauId', nom: 'Mathématiques', cours: [], devoirs: [], td: [], complements: []),
        Matiere(id: 'mat2_$niveauId', nom: 'Statistiques', cours: [], devoirs: [], td: [], complements: []),
      ]),
      UE(id: 'ue2_$niveauId', nom: 'UE2 - Sciences', code: 'UE2', matieres: [
        Matiere(id: 'mat3_$niveauId', nom: 'Informatique', cours: [], devoirs: [], td: [], complements: []),
        Matiere(id: 'mat4_$niveauId', nom: 'Économie', cours: [], devoirs: [], td: [], complements: []),
      ]),
    ];
  }

  // Recherche
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final allDocs = _documentsByNiveau.values.expand((docs) => docs).toList();
    _searchResults = await _gemini.searchDocuments(
      query: query,
      allDocuments: allDocs,
    );

    _isSearching = false;
    notifyListeners();
  }

  // Admin: ajouter document
  void addDocument(String niveauId, Document document) {
    if (!_documentsByNiveau.containsKey(niveauId)) {
      _documentsByNiveau[niveauId] = [];
    }
    _documentsByNiveau[niveauId]!.add(document);
    notifyListeners();
    _saveDocuments();
  }

  // Admin: supprimer document
  void removeDocument(String niveauId, String documentId) {
    _documentsByNiveau[niveauId]?.removeWhere((d) => d.id == documentId);
    notifyListeners();
    _saveDocuments();
  }

  void _saveDocuments() {
    // Sauvegarder les données localement
    // TODO: Implémenter la sérialisation complète
  }

  String? getLastUpdate() {
    return _storage.getLastUpdate();
  }
}
