// lib/services/cloudinary_service.dart
// ═══════════════════════════════════════════════════════════════
// Service Cloudinary — stockage gratuit des fichiers PDF et documents
// Remplace Firebase Storage (qui nécessite un forfait payant)
// ═══════════════════════════════════════════════════════════════
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // ── CONFIGURATION ─────────────────────────────────────────────
  static const String _cloudName = 'dd7bbhsk0';
  static const String _apiKey = '589241278482125';
  static const String _apiSecret = 'jo2Mmqi2a9_wIeZH31CI31pWpao';
  // ignore: unused_field
  static const String _uploadPreset = 'gbaki_docs'; // unsigned preset (à créer)

  // ── UPLOAD ────────────────────────────────────────────────────

  /// Upload un fichier vers Cloudinary
  /// Retourne l'URL publique ou null en cas d'erreur
  Future<String?> uploadFile({
    required String docId,
    required Uint8List bytes,
    required String extension,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload',
      );

      // Signature pour upload sécurisé
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'gbaki_docs/$docId';
      final signature = _generateSignature(
        publicId: publicId,
        timestamp: timestamp,
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['public_id'] = publicId
        ..fields['signature'] = signature
        ..fields['resource_type'] = 'raw'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: '$fileName.$extension',
          ),
        );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (response.statusCode == 200) {
        final url = json['secure_url'] as String?;
        if (kDebugMode) debugPrint('✅ Cloudinary upload OK: $url');
        return url;
      } else {
        if (kDebugMode) debugPrint('❌ Cloudinary erreur: $body');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cloudinary exception: $e');
      return null;
    }
  }

  /// Télécharge un fichier depuis une URL Cloudinary
  Future<Uint8List?> downloadFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cloudinary download erreur: $e');
      return null;
    }
  }

  /// Supprime un fichier de Cloudinary
  Future<void> deleteFile(String docId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'gbaki_docs/$docId';
      final signature = _generateSignature(
        publicId: publicId,
        timestamp: timestamp,
        isDelete: true,
      );

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/raw/destroy',
      );

      await http.post(uri, body: {
        'public_id': publicId,
        'api_key': _apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'resource_type': 'raw',
      });

      if (kDebugMode) debugPrint('✅ Cloudinary fichier supprimé: $publicId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cloudinary delete erreur: $e');
    }
  }

  // ── SIGNATURE ─────────────────────────────────────────────────

  String _generateSignature({
    required String publicId,
    required int timestamp,
    bool isDelete = false,
  }) {
    String toSign;
    if (isDelete) {
      toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    } else {
      toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    }
    final bytes = utf8.encode(toSign);
    return sha1.convert(bytes).toString();
  }

  /// Retourne l'URL publique d'un document depuis son docId
  String getPublicUrl(String docId, String extension) {
    return 'https://res.cloudinary.com/$_cloudName/raw/upload/gbaki_docs/$docId.$extension';
  }
}
