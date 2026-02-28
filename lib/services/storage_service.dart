// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _documentsKey = 'documents_data';
  static const String _adminLoggedKey = 'admin_logged';
  static const String _lastUpdateKey = 'last_update';
  static const String _uesKey = 'ues_data';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Admin
  Future<bool> isAdminLogged() async {
    return _prefs?.getBool(_adminLoggedKey) ?? false;
  }

  Future<void> setAdminLogged(bool value) async {
    await _prefs?.setBool(_adminLoggedKey, value);
  }

  // Documents
  Future<void> saveDocuments(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await _prefs?.setString(_documentsKey, jsonStr);
    await _prefs?.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? loadDocuments() {
    final jsonStr = _prefs?.getString(_documentsKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // UEs data
  Future<void> saveUEs(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await _prefs?.setString(_uesKey, jsonStr);
  }

  Map<String, dynamic>? loadUEs() {
    final jsonStr = _prefs?.getString(_uesKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  String? getLastUpdate() {
    return _prefs?.getString(_lastUpdateKey);
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
