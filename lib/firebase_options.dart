// lib/firebase_options.dart
// ════════════════════════════════════════════════════════════════
// CONFIGURATION FIREBASE — Générée automatiquement
// Projet : gbaki-ensea-da2fe
// ════════════════════════════════════════════════════════════════
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // ── ANDROID ──────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnCSD4ZNTGJxvjJs2D4ZXWQGQKDbF3aJw',
    appId: '1:1017472499112:android:193b4c79c1af802d94719d',
    messagingSenderId: '1017472499112',
    projectId: 'gbaki-ensea-da2fe',
    storageBucket: 'gbaki-ensea-da2fe.firebasestorage.app',
  );

  // ── WEB ──────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnCSD4ZNTGJxvjJs2D4ZXWQGQKDbF3aJw',
    appId: '1:1017472499112:android:193b4c79c1af802d94719d',
    messagingSenderId: '1017472499112',
    projectId: 'gbaki-ensea-da2fe',
    storageBucket: 'gbaki-ensea-da2fe.firebasestorage.app',
    authDomain: 'gbaki-ensea-da2fe.firebaseapp.com',
  );

  // ── iOS ──────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnCSD4ZNTGJxvjJs2D4ZXWQGQKDbF3aJw',
    appId: '1:1017472499112:android:193b4c79c1af802d94719d',
    messagingSenderId: '1017472499112',
    projectId: 'gbaki-ensea-da2fe',
    storageBucket: 'gbaki-ensea-da2fe.firebasestorage.app',
    iosBundleId: 'com.ensealearn.learn',
  );
}
