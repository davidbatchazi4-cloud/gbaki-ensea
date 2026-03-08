// lib/main.dart — v4 Firebase
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Initialiser Firebase ──────────────────────────────────
  bool firebaseOk = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseOk = await FirebaseService().init();
  } catch (e) {
    // Firebase non configuré → mode local uniquement
    debugPrint('Firebase non disponible: $e');
  }

  debugPrint(firebaseOk
      ? '☁️ Mode Cloud Firebase activé'
      : '📱 Mode Local uniquement');

  final provider = AppProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const GbakiEnseaApp(),
    ),
  );
}

class GbakiEnseaApp extends StatefulWidget {
  const GbakiEnseaApp({super.key});
  @override
  State<GbakiEnseaApp> createState() => _GbakiEnseaAppState();
}

class _GbakiEnseaAppState extends State<GbakiEnseaApp> {
  bool _showSplash = true;
  bool _loginDone = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'GBAKI ENSEA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(provider),
    );
  }

  Widget _buildHome(AppProvider provider) {
    if (_showSplash) {
      return SplashScreen(
        onFinish: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    if (!_loginDone) {
      return LoginScreen(
        onLoginDone: () {
          if (mounted) setState(() => _loginDone = true);
        },
      );
    }

    return const HomeScreen();
  }
}
