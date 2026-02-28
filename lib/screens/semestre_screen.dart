// lib/screens/semestre_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'matiere_screen.dart';
import 'admin/add_document_screen.dart';

class SemestreScreen extends StatelessWidget {
  final Filiere filiere;
  final Niveau niveau;
  final Semestre semestre;
  const SemestreScreen({
    super.key,
    required this.filiere,
    required this.niveau,
    required this.semestre,
  });

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
    final provider = context.watch<AppProvider>();
    final ues = provider.getUEsForNiveau(niveau.id);

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: AppTheme.white,
        title: Text('${niveau.nom} • ${semestre.nom}'),
        elevation: 0,
        actions: [
          if (provider.isAdminLogged)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDocumentScreen(
                    filiere: filiere,
                    niveau: niveau,
                    semestre: semestre,
                    ues: ues,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ues.isEmpty
          ? _buildEmptyState(context, provider)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ues.length,
              itemBuilder: (context, index) {
                final ue = ues[index];
                return _UEExpansionCard(
                  ue: ue,
                  color: _color,
                  filiere: filiere,
                  niveau: niveau,
                  isAdmin: provider.isAdminLogged,
                );
              },
            ),
      floatingActionButton: provider.isAdminLogged
          ? FloatingActionButton.extended(
              backgroundColor: _color,
              foregroundColor: AppTheme.white,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDocumentScreen(
                    filiere: filiere,
                    niveau: niveau,
                    semestre: semestre,
                    ues: ues,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: _color.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Aucun document disponible',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les documents seront ajoutés\npar l\'administrateur',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
          if (provider.isAdminLogged) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Ajouter des documents'),
              style: ElevatedButton.styleFrom(backgroundColor: _color),
            ),
          ],
        ],
      ),
    );
  }
}

class _UEExpansionCard extends StatefulWidget {
  final UE ue;
  final Color color;
  final Filiere filiere;
  final Niveau niveau;
  final bool isAdmin;
  const _UEExpansionCard({
    required this.ue,
    required this.color,
    required this.filiere,
    required this.niveau,
    required this.isAdmin,
  });

  @override
  State<_UEExpansionCard> createState() => _UEExpansionCardState();
}

class _UEExpansionCardState extends State<_UEExpansionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _expanded ? widget.color.withValues(alpha: 0.05) : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.ue.code,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.ue.nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.ue.matieres.length} mat.',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.color,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(color: AppTheme.lightGray, height: 1),
            ...widget.ue.matieres.map((matiere) => _MatiereListTile(
                  matiere: matiere,
                  color: widget.color,
                  filiere: widget.filiere,
                  niveau: widget.niveau,
                )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MatiereListTile extends StatelessWidget {
  final Matiere matiere;
  final Color color;
  final Filiere filiere;
  final Niveau niveau;
  const _MatiereListTile({
    required this.matiere,
    required this.color,
    required this.filiere,
    required this.niveau,
  });

  @override
  Widget build(BuildContext context) {
    final totalDocs = matiere.allDocuments.length;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.menu_book_outlined, color: color, size: 20),
      ),
      title: Text(
        matiere.nom,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        totalDocs > 0 ? '$totalDocs document(s)' : 'Aucun document',
        style: TextStyle(
          fontSize: 12,
          color: totalDocs > 0 ? color : AppTheme.textLight,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatiereScreen(
            matiere: matiere,
            filiere: filiere,
            niveau: niveau,
          ),
        ),
      ),
    );
  }
}
