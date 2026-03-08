// lib/screens/login_screen.dart — v3
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginDone;
  const LoginScreen({super.key, required this.onLoginDone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _showAdminForm = false;
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loginError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkBlue.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/ensea_logo.png',
                        width: 90, height: 90, fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'GBAKI ENSEA',
                      style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold,
                        color: AppTheme.white, letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bibliothèque académique intelligente',
                      style: TextStyle(
                        fontSize: 13, color: AppTheme.white.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 48),

                    if (!_showAdminForm) ...[
                      // ─── CHOIX RÔLE ────────────────────────
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: 'Continuer en tant qu\'Étudiant',
                        subtitle: 'Accès à tous les documents et à l\'IA',
                        color: AppTheme.white,
                        textColor: AppTheme.primaryBlue,
                        onTap: () {
                          context.read<AppProvider>().loginUser();
                          widget.onLoginDone();
                        },
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Se connecter en tant qu\'Admin',
                        subtitle: 'Gérer les UEs, matières et documents',
                        color: AppTheme.accentGold,
                        textColor: AppTheme.white,
                        onTap: () => setState(() {
                          _showAdminForm = true;
                          _loginError = false;
                          _passCtrl.clear();
                        }),
                      ),
                    ] else ...[
                      // ─── FORMULAIRE ADMIN ──────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings,
                                      color: AppTheme.accentGold, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Accès Administrateur',
                                  style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Mot de passe',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Entrez le code admin',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                errorText: _loginError ? 'Code incorrect' : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => _tryAdminLogin(),
                            ),
                            if (_loginError) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                                    SizedBox(width: 6),
                                    Text('Code administrateur incorrect',
                                        style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      _showAdminForm = false;
                                      _loginError = false;
                                    }),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Retour'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _tryAdminLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentGold,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: context.watch<AppProvider>().isLoading
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                                color: AppTheme.white, strokeWidth: 2),
                                          )
                                        : const Text('Connexion Admin',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    Text(
                      'ENSEA Abidjan • v3.0',
                      style: TextStyle(
                        fontSize: 11, color: AppTheme.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _tryAdminLogin() async {
    setState(() => _loginError = false);
    final ok = await context.read<AppProvider>().loginAdmin(_passCtrl.text);
    if (mounted) {
      if (ok) {
        widget.onLoginDone();
      } else {
        setState(() => _loginError = true);
      }
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: textColor.withValues(alpha: 0.75))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16,
                color: textColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
