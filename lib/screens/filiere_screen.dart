// lib/screens/filiere_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'niveau_screen.dart';

class FiliereScreen extends StatelessWidget {
  final Filiere filiere;
  const FiliereScreen({super.key, required this.filiere});

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _color,
            foregroundColor: AppTheme.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_color, _color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Text(filiere.icon, style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Filière ${filiere.nom}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                            Text(
                              filiere.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final niveau = filiere.niveaux[index];
                  return _NiveauCard(
                    niveau: niveau,
                    color: _color,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NiveauScreen(
                          filiere: filiere,
                          niveau: niveau,
                        ),
                      ),
                    ),
                  );
                },
                childCount: filiere.niveaux.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _NiveauCard extends StatelessWidget {
  final Niveau niveau;
  final Color color;
  final VoidCallback onTap;
  const _NiveauCard({required this.niveau, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  niveau.nom.substring(0, 2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    niveau.nom,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${niveau.semestres.length} semestres',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Voir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
