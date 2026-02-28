// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GBAKI ENSEA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _showSplash
          ? SplashScreen(
              onFinish: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : const HomeScreen(),
    );
  }
}
