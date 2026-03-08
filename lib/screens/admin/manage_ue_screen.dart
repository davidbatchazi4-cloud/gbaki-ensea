// lib/screens/admin/manage_ue_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class ManageUEScreen extends StatelessWidget {
  final Filiere filiere;
  final Niveau niveau;
  final Semestre semestre;

  const ManageUEScreen({
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
        title: const Text('Gérer les UEs'),
        elevation: 0,
      ),
      body: ues.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ues.length,
              itemBuilder: (ctx, i) => _UEAdminCard(
                ue: ues[i],
                color: _color,
                filiere: filiere,
                niveau: niveau,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _color,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle UE'),
        onPressed: () => _showAddUEDialog(context),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 72, color: _color.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Text('Aucune UE créée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Appuyez sur + pour ajouter une UE',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddUEDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une UE'),
            style: ElevatedButton.styleFrom(backgroundColor: _color),
          ),
        ],
      ),
    );
  }

  void _showAddUEDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nouvelle UE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code UE (ex: UE1, MAT2)',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'UE',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final ue = UE(
                      id: 'ue_${DateTime.now().millisecondsSinceEpoch}',
                      nom: nomCtrl.text.trim(),
                      code: codeCtrl.text.trim().toUpperCase(),
                      niveauId: niveau.id,
                      semestreId: semestre.id,
                      matieres: [],
                    );
                    context.read<AppProvider>().addUE(ue);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('UE "${ue.nom}" créée avec succès'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Créer l\'UE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UEAdminCard extends StatefulWidget {
  final UE ue;
  final Color color;
  final Filiere filiere;
  final Niveau niveau;

  const _UEAdminCard({
    required this.ue,
    required this.color,
    required this.filiere,
    required this.niveau,
  });

  @override
  State<_UEAdminCard> createState() => _UEAdminCardState();
}

class _UEAdminCardState extends State<_UEAdminCard> {
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
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header UE
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
                            color: AppTheme.white, fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.ue.nom,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${widget.ue.matieres.length} matière(s)',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  // Actions UE
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    color: widget.color,
                    tooltip: 'Ajouter une matière',
                    onPressed: () => _showAddMatiereDialog(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.error,
                    tooltip: 'Supprimer UE',
                    onPressed: () => _confirmDeleteUE(context, provider),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.color),
                ],
              ),
            ),
          ),

          // Matières
          if (_expanded) ...[
            Divider(color: AppTheme.lightGray, height: 1),
            if (widget.ue.matieres.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.textLight),
                    const SizedBox(width: 8),
                    const Text('Aucune matière — appuyez sur + ci-dessus',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                  ],
                ),
              )
            else
              ...widget.ue.matieres.map((m) => _MatiereAdminTile(
                    matiere: m,
                    ue: widget.ue,
                    color: widget.color,
                  )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _showAddMatiereDialog(BuildContext context, AppProvider provider) {
    final nomCtrl = TextEditingController();
    final ensCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle matière',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom de la matière *',
                    prefixIcon: Icon(Icons.menu_book_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ensCtrl,
                decoration: const InputDecoration(
                    labelText: 'Enseignant (optionnel)',
                    prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final m = Matiere(
                      id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
                      nom: nomCtrl.text.trim(),
                      ueId: widget.ue.id,
                      enseignant: ensCtrl.text.trim().isEmpty ? null : ensCtrl.text.trim(),
                    );
                    provider.addMatiere(widget.ue.id, m);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                  child: const Text('Ajouter',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUE(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'UE'),
        content: Text(
            'Supprimer "${widget.ue.nom}" et toutes ses matières / documents ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              provider.deleteUE(widget.ue.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _MatiereAdminTile extends StatelessWidget {
  final Matiere matiere;
  final UE ue;
  final Color color;

  const _MatiereAdminTile({
    required this.matiere,
    required this.ue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.menu_book_outlined, color: color, size: 18),
      ),
      title: Text(matiere.nom,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: matiere.enseignant != null
          ? Text(matiere.enseignant!,
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight))
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
        onPressed: () => _confirmDeleteMatiere(context),
      ),
    );
  }

  void _confirmDeleteMatiere(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la matière'),
        content: Text('Supprimer "${matiere.nom}" et tous ses documents ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              context.read<AppProvider>().deleteMatiere(ue.id, matiere.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
