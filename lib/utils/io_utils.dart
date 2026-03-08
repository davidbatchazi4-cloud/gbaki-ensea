// lib/utils/io_utils.dart
// Sélection automatique de l'implémentation selon la plateforme
export 'io_utils_stub.dart'
    if (dart.library.io) 'io_utils_mobile.dart';
