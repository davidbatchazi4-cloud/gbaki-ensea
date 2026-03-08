// lib/screens/semestre_screen.dart — v2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'matiere_screen.dart';
import 'admin/manage_ue_screen.dart';
import 'admin/import_documents_screen.dart';

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
    final ues = provider.getUEsForSemestre(niveau.id, semestre.id);

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: AppTheme.white,
        title: Text('${niveau.nom} • ${semestre.nom}'),
        elevation: 0,
        actions: [
          if (provider.isAdmin) ...[
            // Import de documents
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Importer des documents',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImportDocumentsScreen(
                    filiere: filiere,
                    niveau: niveau,
                    semestre: semestre,
                  ),
                ),
              ),
            ),
            // Gérer les UEs
            IconButton(
              icon: const Icon(Icons.library_books_outlined),
              tooltip: 'Gérer les UEs',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageUEScreen(
                    filiere: filiere,
                    niveau: niveau,
                    semestre: semestre,
                  ),
                ),
              ),
            ),
          ],
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
                  semestre: semestre,
                  isAdmin: provider.isAdmin,
                );
              },
            ),
      // FAB admin
      floatingActionButton: provider.isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'fab_ue',
                  backgroundColor: _color,
                  foregroundColor: AppTheme.white,
                  mini: true,
                  tooltip: 'Gérer les UEs',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageUEScreen(
                        filiere: filiere,
                        niveau: niveau,
                        semestre: semestre,
                      ),
                    ),
                  ),
                  child: const Icon(Icons.library_books_outlined),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'fab_import',
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.white,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Importer'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImportDocumentsScreen(
                        filiere: filiere,
                        niveau: niveau,
                        semestre: semestre,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 80, color: _color.withValues(alpha: 0.25)),
            const SizedBox(height: 20),
            const Text(
              'Aucune UE disponible',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isAdmin
                  ? 'Créez des UEs puis importez\nvos documents'
                  : 'Le contenu sera disponible\naprès mise à jour par l\'admin',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
            ),
            if (provider.isAdmin) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageUEScreen(
                      filiere: filiere,
                      niveau: niveau,
                      semestre: semestre,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Créer une UE'),
                style: ElevatedButton.styleFrom(backgroundColor: _color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UEExpansionCard extends StatefulWidget {
  final UE ue;
  final Color color;
  final Filiere filiere;
  final Niveau niveau;
  final Semestre semestre;
  final bool isAdmin;

  const _UEExpansionCard({
    required this.ue,
    required this.color,
    required this.filiere,
    required this.niveau,
    required this.semestre,
    required this.isAdmin,
  });

  @override
  State<_UEExpansionCard> createState() => _UEExpansionCardState();
}

class _UEExpansionCardState extends State<_UEExpansionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: widget.color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
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
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(widget.ue.code,
                        style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.ue.nom,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${widget.ue.matieres.length} mat.',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
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
            if (widget.ue.matieres.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.isAdmin
                      ? 'Aucune matière — gérez les UEs pour en ajouter'
                      : 'Aucune matière disponible',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              )
            else
              ...widget.ue.matieres.map((matiere) {
                final docCount = provider.allDocuments
                    .where((d) => d.matiereId == matiere.id)
                    .length;
                return _MatiereListTile(
                  matiere: matiere,
                  docCount: docCount,
                  color: widget.color,
                  filiere: widget.filiere,
                  niveau: widget.niveau,
                  isAdmin: widget.isAdmin,
                );
              }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MatiereListTile extends StatelessWidget {
  final Matiere matiere;
  final int docCount;
  final Color color;
  final Filiere filiere;
  final Niveau niveau;
  final bool isAdmin;

  const _MatiereListTile({
    required this.matiere,
    required this.docCount,
    required this.color,
    required this.filiere,
    required this.niveau,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.menu_book_outlined, color: color, size: 20),
      ),
      title: Text(matiere.nom,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        docCount > 0 ? '$docCount document(s)' : 'Aucun document',
        style: TextStyle(
            fontSize: 12,
            color: docCount > 0 ? color : AppTheme.textLight),
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
