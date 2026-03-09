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

  bool get isConfigured => _isConfigured;

  Future<bool> init() async {
    try {
      if (Firebase.apps.isEmpty) return false;
      _db = FirebaseFirestore.instance;
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

  Future<List<UE>> loadUEs() async {
    if (!_isConfigured) return [];
    try {
      final snap = await _db!.collection('ues').get()
          .timeout(const Duration(seconds: 10));
      return snap.docs.map((doc) =>
          UE.fromJson({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement UEs: $e');
      return [];
    }
  }

  Future<void> saveUE(UE ue) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('ues').doc(ue.id).set(ue.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur sauvegarde UE: $e');
    }
  }

  Future<void> deleteUE(String ueId) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('ues').doc(ueId).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur suppression UE: $e');
    }
  }

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

  Future<List<Document>> loadDocuments() async {
    if (!_isConfigured) return [];
    try {
      final snap = await _db!.collection('documents').get()
          .timeout(const Duration(seconds: 10));
      return snap.docs.map((doc) =>
          Document.fromJson({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement documents: $e');
      return [];
    }
  }

  Future<void> saveDocument(Document doc) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(doc.id).set(doc.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur sauvegarde document: $e');
    }
  }

  Future<void> deleteDocument(String docId) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(docId).delete();
      await deleteFile(docId);
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur suppression document: $e');
    }
  }

  Future<void> updateDocumentStorageUrl(String docId, String url) async {
    if (!_isConfigured) return;
    try {
      await _db!.collection('documents').doc(docId)
          .update({'url': url, 'localPath': null});
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur mise à jour URL: $e');
    }
  }

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

  Future<Uint8List?> downloadFile(String docId, String extension) async {
    return await _cloudinary.downloadFromUrl(
        _cloudinary.getPublicUrl(docId, extension));
  }

  Future<Uint8List?> downloadFromUrl(String url) async {
    return await _cloudinary.downloadFromUrl(url);
  }

  Future<void> deleteFile(String docId) async {
    await _cloudinary.deleteFile(docId);
  }

  Stream<List<UE>> streamUEs() {
    if (!_isConfigured) return const Stream.empty();
    return _db!.collection('ues').snapshots().map((snap) =>
        snap.docs.map((doc) =>
            UE.fromJson({...doc.data(), 'id': doc.id})).toList());
  }

  Stream<List<Document>> streamDocuments() {
    if (!_isConfigured) return const Stream.empty();
    return _db!.collection('documents').snapshots().map((snap) =>
        snap.docs.map((doc) =>
            Document.fromJson({...doc.data(), 'id': doc.id})).toList());
  }
}
