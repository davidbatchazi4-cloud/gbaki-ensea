// lib/screens/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _error = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        title: const Text('Espace Administrateur'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 56,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connexion Admin',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Accès réservé à l\'administrateur',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Mot de passe administrateur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        errorText: _error ? 'Mot de passe incorrect' : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le mot de passe';
                        }
                        return null;
                      },
                    ),

                    if (_error) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Mot de passe incorrect',
                              style: TextStyle(color: AppTheme.error, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: AppTheme.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info sur les fonctionnalités admin
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.primaryBlue, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Fonctionnalités administrateur',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...[
                            'Ajouter des documents (PDF, Word, etc.)',
                            'Supprimer des documents',
                            'Gérer les UEs et matières',
                            'Mettre à jour le contenu pour tous',
                          ].map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 14, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(item,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMedium)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = false);
    final provider = context.read<AppProvider>();
    final success = await provider.loginAdmin(_passwordController.text);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.white),
                SizedBox(width: 8),
                Text('Connecté en tant qu\'administrateur'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _error = true);
      }
    }
  }
}
