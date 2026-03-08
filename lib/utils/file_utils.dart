// lib/utils/file_utils.dart
// Sélection automatique de l'implémentation selon la plateforme
// Web → stub (pas de dart:io), Mobile/Desktop → implémentation réelle
export 'file_utils_stub.dart'
    if (dart.library.io) 'file_utils_mobile.dart';
