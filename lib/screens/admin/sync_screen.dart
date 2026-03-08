// lib/screens/admin/sync_screen.dart — v6 Firebase Cloud + .gbaki fallback
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../utils/io_utils.dart';
import '../../utils/file_utils.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Export
  bool _isExporting = false;
  String? _exportError;
  bool _exportDone = false;
  String _exportSummary = '';

  // Import
  bool _isImporting = false;
  String? _importResult;

  // Refresh cloud
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final initialTab = provider.isAdmin ? 0 : 1;
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialTab);
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
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        title: Row(
          children: [
            const Icon(Icons.sync, size: 20),
            const SizedBox(width: 8),
            const Text('Synchronisation'),
            const SizedBox(width: 8),
            if (provider.firebaseEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 12, color: AppTheme.success),
                    SizedBox(width: 4),
                    Text('Cloud', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 3,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withValues(alpha: 0.5),
          tabs: const [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_outlined, size: 16),
                SizedBox(width: 6),
                Text('Admin — Gérer', style: TextStyle(fontSize: 12)),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_outlined, size: 16),
                SizedBox(width: 6),
                Text('Étudiant — Recevoir', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(provider),
          _buildImportTab(provider),
        ],
      ),
    );
  }

  // ─── ONGLET EXPORT (admin) ────────────────────────────────

  Widget _buildExportTab(AppProvider provider) {
    if (!provider.isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 20),
              const Text('Accès réservé à l\'administrateur',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Seul l\'administrateur peut gérer la synchronisation.\n\n'
                'Rendez-vous dans l\'onglet "Étudiant — Recevoir" pour importer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Aller à Recevoir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6E5C),
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode Firebase actif ──────────────────────────
          if (provider.firebaseEnabled) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        '✅ Firebase Cloud Actif',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Les documents que vous importez sont automatiquement\n'
                    'uploadés vers Firebase Storage et visibles par tous\n'
                    'les utilisateurs dès l\'ouverture de l\'app.\n\n'
                    '🚀 Plus besoin de partager manuellement !',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  // Bouton forcer sync
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isRefreshing ? null : () => _refreshCloud(provider),
                      icon: _isRefreshing
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.refresh, color: Colors.white, size: 16),
                      label: Text(
                        _isRefreshing ? 'Synchronisation...' : 'Forcer la synchronisation',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Stats ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Données actuelles',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _statRow(Icons.class_outlined, 'UEs', '${provider.allUEs.length}'),
                _statRow(Icons.folder_outlined, 'Documents', '${provider.allDocuments.length}'),
                _statRow(
                  provider.firebaseEnabled ? Icons.cloud_outlined : Icons.storage_outlined,
                  'Stockage',
                  provider.firebaseEnabled ? 'Firebase Cloud ☁️' : 'Local uniquement 📱',
                ),
                if (!provider.firebaseEnabled)
                  _statRow(
                    Icons.save_outlined,
                    'Fichiers locaux',
                    '${provider.allDocuments.where((d) => provider.hasDocumentBytes(d.id)).length} avec copie',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Mode sans Firebase : partage fichier ─────────
          if (!provider.firebaseEnabled) ...[
            _infoCard(
              icon: Icons.info_outline,
              color: AppTheme.primaryBlue,
              title: 'Mode local — Partage manuel',
              content: '1. Appuyez sur "Générer et partager"\n'
                  '2. Un fichier "sync_ensea.gbaki" est créé\n'
                  '3. Partagez via WhatsApp, email, Telegram…\n'
                  '4. Les étudiants ouvrent l\'onglet "Recevoir"\n\n'
                  '💡 Pour un partage automatique, configurez Firebase.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _generateAndShare(provider),
                icon: _isExporting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                    : const Icon(Icons.share),
                label: Text(_isExporting ? 'Génération...' : 'Générer et partager le fichier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (_exportError != null) ...[
              const SizedBox(height: 12),
              _errorContainer(_exportError!),
            ],

            if (_exportDone) ...[
              const SizedBox(height: 16),
              _successContainer(
                '${provider.allUEs.length} UEs · ${provider.allDocuments.length} documents\n$_exportSummary',
                onRetry: () => _generateAndShare(provider),
              ),
            ],
          ],

          // ── Aide Firebase non configuré ──────────────────
          if (!provider.firebaseEnabled) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined, color: AppTheme.accentGold, size: 18),
                      SizedBox(width: 8),
                      Text('Activer Firebase Cloud',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remplacez les valeurs dans firebase_options.dart\n'
                    'et android/app/google-services.json avec votre\n'
                    'propre projet Firebase pour activer le cloud.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMedium, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── ONGLET IMPORT (étudiant) ────────────────────────────

  Widget _buildImportTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Firebase actif : bouton refresh ─────────────
          if (provider.firebaseEnabled) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6E5C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0D6E5C).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_sync, color: Color(0xFF0D6E5C), size: 22),
                      SizedBox(width: 10),
                      Text('Données cloud automatiques',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6E5C), fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vos données sont automatiquement chargées depuis Firebase.\n'
                    'L\'admin n\'a plus besoin de vous envoyer un fichier.\n\n'
                    '• Appuyez sur "Rafraîchir" pour charger les dernières mises à jour.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : () => _refreshCloud(provider),
                      icon: _isRefreshing
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(_isRefreshing ? 'Chargement...' : 'Rafraîchir les données'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6E5C),
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.textLight.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou migration depuis fichier .gbaki',
                      style: TextStyle(fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.7))),
                ),
                Expanded(child: Divider(color: AppTheme.textLight.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Import .gbaki ────────────────────────────────
          _infoCard(
            icon: Icons.download_outlined,
            color: const Color(0xFF0D6E5C),
            title: provider.firebaseEnabled
                ? 'Migration : importer un fichier .gbaki'
                : 'Recevoir les mises à jour',
            content: provider.firebaseEnabled
                ? 'Si vous avez un ancien fichier .gbaki,\nimportez-le pour migrer vos données vers le cloud.\nL\'admin n\'a plus besoin de partager des fichiers.'
                : 'L\'administrateur vous partage un fichier "sync_ensea.gbaki".\n'
                    'Téléchargez-le puis appuyez sur le bouton ci-dessous.\n\n'
                    '📱 Partagé via WhatsApp / Email / Telegram',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : () => _importFromFile(provider),
              icon: _isImporting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                  : const Icon(Icons.file_open_outlined),
              label: Text(_isImporting ? 'Importation...' : 'Sélectionner un fichier .gbaki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6E5C),
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          if (!provider.firebaseEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Comment trouver le fichier ?\n'
                '1. Ouvrez WhatsApp / Email\n'
                '2. Trouvez le message de l\'admin\n'
                '3. Téléchargez le fichier "sync_ensea.gbaki"\n'
                '4. Revenez ici et appuyez sur "Sélectionner"',
                style: TextStyle(fontSize: 12, color: AppTheme.textMedium, height: 1.6),
              ),
            ),
          ],

          if (_importResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _importResult!.startsWith('✅')
                    ? AppTheme.success.withValues(alpha: 0.08)
                    : AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _importResult!.startsWith('✅')
                      ? AppTheme.success.withValues(alpha: 0.3)
                      : AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _importResult!,
                style: TextStyle(
                  fontSize: 14,
                  color: _importResult!.startsWith('✅') ? AppTheme.success : AppTheme.error,
                  height: 1.6,
                ),
              ),
            ),
            if (_importResult!.startsWith('✅')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Retour à l\'accueil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────

  Future<void> _refreshCloud(AppProvider provider) async {
    setState(() => _isRefreshing = true);
    await provider.refreshFromCloud();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${provider.allDocuments.length} documents chargés depuis le cloud'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _generateAndShare(AppProvider provider) async {
    setState(() { _isExporting = true; _exportError = null; _exportDone = false; });
    try {
      final jsonData = await provider.generateSyncData();
      final bytes = Uint8List.fromList(utf8.encode(jsonData));
      final sizeKb = (bytes.length / 1024).toStringAsFixed(1);

      if (kIsWeb) {
        await _downloadOnWeb(bytes);
      } else {
        await _shareOnMobile(bytes, provider);
      }

      if (mounted) {
        setState(() {
          _exportDone = true;
          _isExporting = false;
          _exportSummary = 'Taille : $sizeKb KB\nFichier "sync_ensea.gbaki" partagé.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _exportError = 'Erreur : $e'; _isExporting = false; });
      }
    }
  }

  Future<void> _shareOnMobile(Uint8List bytes, AppProvider provider) async {
    final tempPath = await writeBytesToTempFile(bytes, 'gbaki', 'sync_ensea');
    if (tempPath == null) throw Exception('Impossible d\'écrire le fichier temporaire.');
    final xFile = XFile(tempPath, mimeType: 'application/octet-stream');
    await Share.shareXFiles(
      [xFile],
      subject: 'GBAKI ENSEA — Synchronisation',
      text: 'Fichier de sync GBAKI ENSEA (${provider.allDocuments.length} docs). '
          'Sync → Recevoir → Sélectionner.',
    );
  }

  Future<void> _downloadOnWeb(Uint8List bytes) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Télécharger sync_ensea.gbaki'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fichier prêt (${(bytes.length / 1024).toStringAsFixed(1)} KB). Sélectionnez et copiez le contenu.'),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: SelectableText(utf8.decode(bytes),
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _importFromFile(AppProvider provider) async {
    setState(() { _isImporting = true; _importResult = null; });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false, withData: true);
      if (result == null || result.files.isEmpty) { setState(() => _isImporting = false); return; }

      final file = result.files.first;
      String jsonData;
      if (file.bytes != null) {
        jsonData = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        final bytes = await readFileBytes(file.path!);
        if (bytes == null) throw Exception('Impossible de lire le fichier');
        jsonData = utf8.decode(bytes);
      } else {
        throw Exception('Fichier inaccessible');
      }

      try { jsonDecode(jsonData); } catch (_) {
        throw Exception('Fichier invalide (pas un fichier .gbaki valide)');
      }

      final success = await provider.importSyncData(jsonData);
      if (!mounted) return;

      if (success) {
        setState(() {
          _importResult = '✅ Synchronisation réussie !\n\n'
              '• ${provider.allUEs.length} UEs\n'
              '• ${provider.allDocuments.length} documents\n'
              + (provider.firebaseEnabled ? '\n☁️ Données migrées vers Firebase.' : '');
        });
      } else {
        setState(() => _importResult = '❌ Fichier corrompu ou incompatible.');
      }
    } catch (e) {
      if (mounted) setState(() => _importResult = '❌ Erreur : $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  Widget _infoCard({required IconData icon, required Color color, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
          ])),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium))),
        ],
      ),
    );
  }

  Widget _errorContainer(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
      ]),
    );
  }

  Widget _successContainer(String msg, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 8),
          const Text('Fichier partagé !', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.share),
              label: const Text('Partager à nouveau'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue, side: const BorderSide(color: AppTheme.primaryBlue)),
            ),
          ),
        ],
      ]),
    );
  }
}
