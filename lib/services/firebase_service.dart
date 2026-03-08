// lib/services/firebase_service.dart
// ═══════════════════════════════════════════════════════════════
// Service Firebase centralisé : Firestore (métadonnées) + Cloudinary (fichiers)
// Fallback automatique sur Hive si Firebase non configuré
// ═══════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'cloudinary_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? _db;
  final CloudinaryService _cloudinary = CloudinaryService();
  bool _isConfigured = false;

  /// Vérifie si Firebase est correctement configuré (pas de valeurs placeholder)
  bool get isConfigured => _isConfigured;

  /// Initialise Firebase — retourne true si succès, false si placeholder
  Future<bool> init() async {
    try {
      // Vérifier si l'app Firebase est déjà initialisée
      if (Firebase.apps.isEmpty) {
        return false;
      }

      _db = FirebaseFirestore.instance;

      // Test de connexion rapide pour vérifier la config
      await _db!.collection('_ping').limit(1).get()
          .timeout(const Duration(seconds: 5));

      _isConfigured = true;
      if (kDebugMode) debugPrint('✅ Firebase connecté');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firebase non configuré : $e');
      _isConfigured = false;
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE — UEs
  // ═══════════════════════════════════════════════════════════════

  /// Charge toutes les UEs depuis Firestore
  Future<List<UE>> loadUEs() async {
    if (!_isConfigured) return [];
    try {
      final snap = await _db!.collection('ues').get()
          .timeout(const Duration(seconds: 10));
      return snap.docs.map((doc) {
        final data = doc.data();
        return UE.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement UEs: $e');
      return [];
    }
  }

  /// Sauvegarde ou met à jour une UE dans Firestore
  Future<void> saveUE(UE ue) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('ues').doc(ue.id).set(ue.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur sauvegarde UE: $e');
    }
  }

  /// Supprime une UE de Firestore
  Future<void> deleteUE(String ueId) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('ues').doc(ueId).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur suppression UE: $e');
    }
  }

  /// Sauvegarde toutes les UEs (bulk)
  Future<void> saveAllUEs(List<UE> ues) async {
    if (!_isConfigured) return;
    try {
      final batch = _db!.batch();
      for (final ue in ues) {
        batch.set(_db!.collection('ues').doc(ue.id), ue.toJson());
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur sauvegarde UEs bulk: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE — Documents
  // ═══════════════════════════════════════════════════════════════

  /// Charge tous les documents depuis Firestore
  Future<List<Document>> loadDocuments() async {
    if (!_isConfigured) return [];
    try {
      final snap = await _db!.collection('documents').get()
          .timeout(const Duration(seconds: 10));
      return snap.docs.map((doc) {
        final data = doc.data();
        return Document.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement documents: $e');
      return [];
    }
  }

  /// Sauvegarde un document dans Firestore
  Future<void> saveDocument(Document doc) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(doc.id).set(doc.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur sauvegarde document: $e');
    }
  }

  /// Supprime un document de Firestore
  Future<void> deleteDocument(String docId) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(docId).delete();
      // Supprimer aussi le fichier dans Storage
      await deleteFile(docId);
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur suppression document: $e');
    }
  }

  /// Met à jour le champ storageUrl d'un document après upload
  Future<void> updateDocumentStorageUrl(String docId, String url) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(docId).update({'url': url, 'localPath': null});
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur mise à jour URL: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLOUDINARY — Fichiers binaires (PDF, docs, etc.)
  // ═══════════════════════════════════════════════════════════════

  /// Upload un fichier vers Cloudinary
  /// Retourne l'URL de téléchargement ou null en cas d'erreur
  Future<String?> uploadFile({
    required String docId,
    required Uint8List bytes,
    required String extension,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _cloudinary.uploadFile(
      docId: docId,
      bytes: bytes,
      extension: extension,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Télécharge un fichier depuis une URL Cloudinary
  Future<Uint8List?> downloadFile(String docId, String extension) async {
    final url = _cloudinary.getPublicUrl(docId, extension);
    return await _cloudinary.downloadFromUrl(url);
  }

  /// Télécharge un fichier depuis une URL directe
  Future<Uint8List?> downloadFromUrl(String url) async {
    return await _cloudinary.downloadFromUrl(url);
  }

  /// Supprime un fichier de Cloudinary
  Future<void> deleteFile(String docId) async {
    await _cloudinary.deleteFile(docId);
  }

  // ─── HELPERS ───────────────────────────────────────────────────

  /// Retourne le stream de mise à jour en temps réel des UEs
  Stream<List<UE>> streamUEs() {
    if (!_isConfigured) return const Stream.empty();
    return _db!.collection('ues').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return UE.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// Retourne le stream de mise à jour en temps réel des documents
  Stream<List<Document>> streamDocuments() {
    if (!_isConfigured) return const Stream.empty();
    return _db!.collection('documents').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return Document.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }
}
