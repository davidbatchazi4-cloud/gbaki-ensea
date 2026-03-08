// lib/screens/matiere_screen.dart — v2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'document_screen.dart';

class MatiereScreen extends StatefulWidget {
  final Matiere matiere;
  final Filiere filiere;
  final Niveau niveau;

  const MatiereScreen({
    super.key,
    required this.matiere,
    required this.filiere,
    required this.niveau,
  });

  @override
  State<MatiereScreen> createState() => _MatiereScreenState();
}

class _MatiereScreenState extends State<MatiereScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<TypeDocument> _types = TypeDocument.values;

  Color get _color {
    switch (widget.filiere.id) {
      case 'as': return const Color(0xFF1B4B8A);
      case 'ise': return const Color(0xFF0D6E5C);
      case 'ips': return const Color(0xFF5B2D8A);
      default: return AppTheme.primaryBlue;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: AppTheme.white,
        title: Text(widget.matiere.nom),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white,
          indicatorWeight: 3,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _types.map((t) => Tab(
            icon: Text(t.emoji, style: const TextStyle(fontSize: 16)),
            text: t.label,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types.map((type) {
          final docs = provider.getDocumentsForMatiere(widget.matiere.id, type);
          return _DocumentList(
            documents: docs,
            color: _color,
            type: type,
            isAdmin: provider.isAdmin,
            onDelete: (docId) => provider.deleteDocument(docId),
          );
        }).toList(),
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final List<Document> documents;
  final Color color;
  final TypeDocument type;
  final bool isAdmin;
  final Function(String) onDelete;

  const _DocumentList({
    required this.documents,
    required this.color,
    required this.type,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text('Aucun ${type.label} disponible',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 8),
            const Text('L\'administrateur peut importer\ndes documents ici',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) => _DocumentCard(
        document: documents[index],
        color: color,
        isAdmin: isAdmin,
        onDelete: () => _confirmDelete(context, documents[index]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${doc.titre}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(doc.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('"${doc.titre}" supprimé'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final Color color;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.color,
    required this.isAdmin,
    required this.onDelete,
  });

  IconData get _fileIcon {
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isWord) return Icons.description;
    if (document.isExcel) return Icons.table_chart;
    if (document.isPowerPoint) return Icons.slideshow;
    if (document.isPython) return Icons.code;
    if (document.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color get _fileColor {
    if (document.isPdf) return const Color(0xFFE74C3C);
    if (document.isWord) return const Color(0xFF2B5DBB);
    if (document.isExcel) return const Color(0xFF1D6F42);
    if (document.isPowerPoint) return const Color(0xFFD04523);
    if (document.isPython) return const Color(0xFF3776AB);
    return const Color(0xFF6C757D);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentScreen(document: document)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: _fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_fileIcon, color: _fileColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.titre,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppTheme.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(document.extension.toUpperCase(), _fileColor),
                      if (document.taille != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(document.taille!, AppTheme.textLight),
                      ],
                      if (document.hasLocalFile) ...[
                        const SizedBox(width: 6),
                        _buildTag('📱 Local', AppTheme.success),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.white, size: 12),
                      SizedBox(width: 4),
                      Text('IA',
                          style: TextStyle(
                              color: AppTheme.white, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.delete_outline,
                          color: AppTheme.error, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: c)),
      );
}
