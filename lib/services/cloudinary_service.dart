import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  static const String _cloudName = 'dd7bbhsk0';
  static const String _apiKey = '589241278482125';
  static const String _apiSecret = 'jo2Mmqi2a9_wIeZH31CI31pWpao';

  Future<String?> uploadFile({
    required String docId,
    required Uint8List bytes,
    required String extension,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/raw/upload');
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'gbaki_docs/$docId';
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['public_id'] = publicId
        ..fields['signature'] = signature
        ..fields['resource_type'] = 'raw'
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: '$fileName.$extension'));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      if (response.statusCode == 200) return json['secure_url'] as String?;
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Cloudinary erreur: $e');
      return null;
    }
  }

  Future<Uint8List?> downloadFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (e) { return null; }
  }

  Future<void> deleteFile(String docId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'gbaki_docs/$docId';
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();
      await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/raw/destroy'),
        body: {'public_id': publicId, 'api_key': _apiKey, 'timestamp': timestamp.toString(), 'signature': signature, 'resource_type': 'raw'},
      );
    } catch (e) { if (kDebugMode) debugPrint('Cloudinary delete erreur: $e'); }
  }

  String getPublicUrl(String docId, String extension) =>
      'https://res.cloudinary.com/$_cloudName/raw/upload/gbaki_docs/$docId.$extension';
}
