// lib/screens/document_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'ai_learn_screen.dart';

class DocumentScreen extends StatelessWidget {
  final Document document;
  const DocumentScreen({super.key, required this.document});

  Color get _fileColor {
    if (document.isPdf) return const Color(0xFFE74C3C);
    if (document.isWord) return const Color(0xFF2B5DBB);
    if (document.isExcel) return const Color(0xFF1D6F42);
    if (document.isPowerPoint) return const Color(0xFFD04523);
    if (document.isPython) return const Color(0xFF3776AB);
    return const Color(0xFF6C757D);
  }

  IconData get _fileIcon {
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isWord) return Icons.description;
    if (document.isExcel) return Icons.table_chart;
    if (document.isPowerPoint) return Icons.slideshow;
    if (document.isPython) return Icons.code;
    if (document.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        title: const Text('Document'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header du document
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(_fileIcon, color: _fileColor, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    document.titre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(document.typeLabel, Icons.label_outline),
                      const SizedBox(width: 8),
                      _buildChip(document.extension.toUpperCase(), Icons.insert_drive_file_outlined),
                      if (document.matiereName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildChip(document.matiereName, Icons.menu_book_outlined),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton principal : Apprendre avec l'IA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AILearnScreen(document: document),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C3FA5), Color(0xFF4A90D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C3FA5).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apprendre avec l\'IA',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Résumé • Quiz • Fiches • Explications',
                              style: TextStyle(
                                color: AppTheme.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppTheme.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.open_in_new,
                      label: 'Ouvrir',
                      color: AppTheme.primaryBlue,
                      onTap: () => _openDocument(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Partager',
                      color: AppTheme.lightBlue,
                      onTap: () => _shareDocument(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informations du document
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (document.description != null)
                    _buildInfoRow(Icons.info_outline, 'Description', document.description!),
                  _buildInfoRow(Icons.label_outline, 'Type', document.typeLabel),
                  _buildInfoRow(Icons.insert_drive_file_outlined, 'Format', document.extension.toUpperCase()),
                  _buildInfoRow(Icons.menu_book_outlined, 'Matière', document.matiereName),
                  if (document.taille != null)
                    _buildInfoRow(Icons.storage_outlined, 'Taille', document.taille!),
                  if (document.dateAjout != null)
                    _buildInfoRow(Icons.calendar_today_outlined, 'Date ajout',
                        '${document.dateAjout!.day}/${document.dateAjout!.month}/${document.dateAjout!.year}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Text('$label : ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              )),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context) async {
    final uri = Uri.tryParse(document.url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le document')),
          );
        }
      }
    }
  }

  void _shareDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien copié : ${document.url}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
