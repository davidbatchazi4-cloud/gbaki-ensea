// lib/screens/niveau_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'semestre_screen.dart';

class NiveauScreen extends StatelessWidget {
  final Filiere filiere;
  final Niveau niveau;
  const NiveauScreen({super.key, required this.filiere, required this.niveau});

  Color get _color {
    switch (filiere.id) {
      case 'as': return const Color(0xFF1B4B8A);
      case 'ise': return const Color(0xFF0D6E5C);
      case 'ips': return const Color(0xFF5B2D8A);
      default: return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: AppTheme.white,
        title: Text(niveau.nom),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: AppTheme.white.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  '${niveau.semestres.length} semestres disponibles',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sélectionnez un semestre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: niveau.semestres.length,
              itemBuilder: (context, index) {
                final semestre = niveau.semestres[index];
                return _SemestreCard(
                  semestre: semestre,
                  color: _color,
                  numero: index + 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SemestreScreen(
                        filiere: filiere,
                        niveau: niveau,
                        semestre: semestre,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SemestreCard extends StatelessWidget {
  final Semestre semestre;
  final Color color;
  final int numero;
  final VoidCallback onTap;
  const _SemestreCard({
    required this.semestre,
    required this.color,
    required this.numero,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'S$numero',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semestre.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UEs, Cours, Devoirs & TD',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
