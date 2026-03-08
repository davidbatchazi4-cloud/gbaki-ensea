// lib/screens/document_screen.dart — v8 : chargement bytes garanti depuis Hive ou localPath
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';
import '../utils/io_utils.dart';
import 'ai_learn_screen.dart';

class DocumentScreen extends StatefulWidget {
  final Document document;
  const DocumentScreen({super.key, required this.document});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  bool _isLoadingFile = false;
  Uint8List? _fileBytes;
  String? _fileError;
  bool _showViewer = false;
  bool _isLoadingBytes = false; // Chargement initial des bytes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBytesFromStorage());
  }

  /// Charge les bytes depuis Hive (cache) OU Firebase Storage OU fichier local
  Future<void> _loadBytesFromStorage() async {
    if (!mounted) return;
    setState(() => _isLoadingBytes = true);

    final provider = context.read<AppProvider>();

    // 1. Cache Hive local (prioritaire — pas de réseau)
    Uint8List? bytes = provider.getDocumentBytes(widget.document.id);

    // 2. Firebase Storage (si pas en cache local)
    if ((bytes == null || bytes.isEmpty)) {
      bytes = await provider.fetchDocumentBytes(widget.document.id);
    }

    // 3. Fallback : lire depuis le chemin local (mobile, import direct)
    if ((bytes == null || bytes.isEmpty) &&
        !kIsWeb &&
        widget.document.hasLocalFile) {
      bytes = await readFileBytes(widget.document.localPath!);
      if (bytes != null && bytes.isNotEmpty) {
        await provider.cacheDocumentBytes(widget.document.id, bytes);
      }
    }

    if (mounted) {
      setState(() {
        _fileBytes = bytes;
        _isLoadingBytes = false;
      });
    }
  }

  Color get _fileColor {
    if (widget.document.isPdf) return const Color(0xFFE74C3C);
    if (widget.document.isWord) return const Color(0xFF2B5DBB);
    if (widget.document.isExcel) return const Color(0xFF1D6F42);
    if (widget.document.isPowerPoint) return const Color(0xFFD04523);
    if (widget.document.isPython) return const Color(0xFF3776AB);
    if (widget.document.isImage) return const Color(0xFF9B59B6);
    return const Color(0xFF6C757D);
  }

  IconData get _fileIcon {
    if (widget.document.isPdf) return Icons.picture_as_pdf;
    if (widget.document.isWord) return Icons.description;
    if (widget.document.isExcel) return Icons.table_chart;
    if (widget.document.isPowerPoint) return Icons.slideshow;
    if (widget.document.isPython) return Icons.code;
    if (widget.document.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  bool get _hasBytes => _fileBytes != null && _fileBytes!.isNotEmpty;

  // Un fichier physique est disponible si : bytes en mémoire OU chemin local sur mobile
  // Note : on N'inclut PAS widget.document.url ici pour éviter d'afficher
  // "Ouvrir" quand il n'y a que l'URL (car on aurait "Aucun fichier disponible")
  bool get _hasFile =>
      _hasBytes ||
      (!kIsWeb && widget.document.hasLocalFile);

  bool get _canViewInApp {
    final ext = widget.document.extension.toLowerCase();
    return _hasBytes &&
        (['txt', 'py', 'md', 'csv', 'json', 'html', 'xml', 'log'].contains(ext) ||
            widget.document.isImage ||
            widget.document.isPdf);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        title: Text(
          widget.document.titre,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
        elevation: 0,
        actions: [
          if (_isLoadingBytes)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else if (_hasFile)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Ouvrir',
              onPressed: () => _openDocument(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Header bleu ──────────────────────────
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
                    widget.document.titre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(widget.document.typeLabel, Icons.label_outline),
                      _chip(widget.document.extension.toUpperCase(),
                          Icons.insert_drive_file_outlined),
                      if (widget.document.matiereName.isNotEmpty)
                        _chip(widget.document.matiereName, Icons.menu_book_outlined),
                      if (_hasBytes)
                        _chip('✓ Copie locale', Icons.offline_pin_outlined),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Bouton IA ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AILearnScreen(
                      document: widget.document,
                      preloadedBytes: _fileBytes,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A2580), Color(0xFF1B4B8A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A2580).withValues(alpha: 0.35),
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
                        child: const Icon(Icons.auto_awesome,
                            color: AppTheme.white, size: 28),
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _hasBytes
                                  ? '✓ L\'IA peut lire ce document • Chat • Résumé • Quiz'
                                  : 'Chat • Résumé • Quiz • Fiches de révision',
                              style: TextStyle(
                                  color: AppTheme.white.withValues(alpha: 0.85),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ─── Actions (Ouvrir / Lien) ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildActionsSection(context),
            ),

            const SizedBox(height: 14),

            // ─── Visionneuse intégrée ─────────────────
            if (_showViewer && _hasBytes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildIntegratedViewer(),
              ),

            const SizedBox(height: 14),

            // ─── Informations ─────────────────────────
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
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  if (widget.document.description != null)
                    _infoRow(Icons.info_outline, 'Description',
                        widget.document.description!),
                  _infoRow(
                      Icons.label_outline, 'Type', widget.document.typeLabel),
                  _infoRow(Icons.insert_drive_file_outlined, 'Format',
                      widget.document.extension.toUpperCase()),
                  _infoRow(Icons.menu_book_outlined, 'Matière',
                      widget.document.matiereName),
                  if (widget.document.taille != null)
                    _infoRow(Icons.storage_outlined, 'Taille',
                        widget.document.taille!),
                  if (widget.document.dateAjout != null)
                    _infoRow(Icons.calendar_today_outlined, 'Date d\'ajout',
                        _formatDate(widget.document.dateAjout!)),
                  _infoRow(
                    _hasBytes ? Icons.check_circle_outline : Icons.cloud_outlined,
                    'Stockage',
                    _hasBytes
                        ? '✓ Copie locale (disponible hors-ligne)'
                        : widget.document.url != null
                            ? 'Lien en ligne uniquement'
                            : 'Non disponible',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Section actions ──────────────────────────────────────────

  Widget _buildActionsSection(BuildContext context) {
    final hasUrl =
        widget.document.url != null && widget.document.url!.isNotEmpty;
    // Fichier disponible si : bytes en mémoire OU localPath valide (mobile)
    // On exclut l'URL ici car elle est gérée séparément avec le bouton "Lien en ligne"
    final hasFile = _hasBytes ||
        (!kIsWeb && widget.document.hasLocalFile) ||
        _isLoadingBytes;

    // Afficher spinner pendant le chargement initial
    if (_isLoadingBytes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: AppTheme.primaryBlue, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement du fichier…',
                style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            if (hasFile)
              Expanded(
                child: _ActionButton(
                  icon: Icons.folder_open_outlined,
                  label: _isLoadingFile ? 'Ouverture...' : 'Ouvrir',
                  color: AppTheme.primaryBlue,
                  onTap: () => _openDocument(context),
                  isLoading: _isLoadingFile,
                ),
              ),
            if (hasFile && hasUrl) const SizedBox(width: 10),
            if (hasUrl)
              Expanded(
                child: _ActionButton(
                  icon: Icons.open_in_browser,
                  label: 'Lien en ligne',
                  color: const Color(0xFF0D6E5C),
                  onTap: () => _openUrl(context),
                ),
              ),
          ],
        ),

        // Si aucune action disponible
        if (!hasFile && !hasUrl)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.textLight, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aucun fichier associé à ce document.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ℹ️ L\'administrateur doit importer ce fichier via\n'
                    '"Importer des documents" puis partager un\n'
                    'nouveau code de synchronisation aux étudiants.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMedium, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

        // Bouton visionneuse intégrée
        if (_canViewInApp) ...[
          const SizedBox(height: 10),
          _ActionButton(
            icon: _showViewer
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: _showViewer
                ? 'Fermer la visionneuse'
                : 'Voir dans l\'application',
            color: const Color(0xFF5B2D8A),
            onTap: () => setState(() => _showViewer = !_showViewer),
            fullWidth: true,
          ),
        ],

        // Erreur
        if (_fileError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_fileError!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.error, height: 1.4)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _fileError = null),
                  child: const Icon(Icons.close, size: 16, color: AppTheme.error),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Visionneuse intégrée ─────────────────────────────────────

  Widget _buildIntegratedViewer() {
    final ext = widget.document.extension.toLowerCase();

    // Image
    if (widget.document.isImage) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(_fileBytes!, fit: BoxFit.contain),
        ),
      );
    }

    // Texte / Code
    if (['txt', 'py', 'md', 'csv', 'json', 'html', 'xml', 'log'].contains(ext)) {
      String text;
      try {
        text = utf8.decode(_fileBytes!, allowMalformed: true);
      } catch (_) {
        text = latin1.decode(_fileBytes!.toList());
      }
      final lineCount = '\n'.allMatches(text).length + 1;
      final isPy = ext == 'py';

      return Container(
        decoration: BoxDecoration(
          color: isPy ? const Color(0xFF1E1E2E) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPy ? Icons.code : Icons.article_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.document.titre}.${ext.toUpperCase()} • $lineCount lignes',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPy
                        ? const Color(0xFFCDD6F4)
                        : const Color(0xFFD4D4D4),
                    fontFamily: 'monospace',
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // PDF
    if (widget.document.isPdf) {
      final sizeStr = widget.document.taille ??
          '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB';
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf,
                color: Color(0xFFE74C3C), size: 56),
            const SizedBox(height: 12),
            Text(
              '${widget.document.titre}.pdf',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(sizeStr,
                style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              '📄 Le fichier PDF est stocké dans l\'application.\nAppuyez sur "Ouvrir PDF" pour le lire,\nou utilisez "Apprendre avec l\'IA" pour analyser son contenu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textMedium, height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openDocument(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AILearnScreen(
                        document: widget.document,
                        preloadedBytes: _fileBytes,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('IA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A2580),
                    side: const BorderSide(color: Color(0xFF4A2580)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Office (Word, Excel, PowerPoint)
    if (widget.document.isWord ||
        widget.document.isExcel ||
        widget.document.isPowerPoint) {
      final color = widget.document.isWord
          ? const Color(0xFF2B5DBB)
          : widget.document.isExcel
              ? const Color(0xFF1D6F42)
              : const Color(0xFFD04523);
      final typeLabel = widget.document.isWord
          ? 'Document Word'
          : widget.document.isExcel
              ? 'Feuille Excel'
              : 'Présentation PowerPoint';
      final size = widget.document.taille ??
          '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(_fileIcon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              '${widget.document.titre}.${widget.document.extension}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(size,
                style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              '$typeLabel stocké dans l\'application.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openDocument(context),
              icon: Icon(_fileIcon),
              label: const Text('Ouvrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Ouverture du document ────────────────────────────────────

  Future<void> _openDocument(BuildContext context) async {
    // ─── WEB : télécharger via Data URL ─────────────────────────
    if (kIsWeb) {
      if (_hasBytes) {
        await _downloadFileWeb(context, _fileBytes!, widget.document);
      } else if (widget.document.url != null) {
        await _openUrl(context);
      } else {
        setState(() => _showViewer = true);
      }
      return;
    }

    // ─── MOBILE : trouver le chemin ou écrire un fichier temp ───
    setState(() {
      _isLoadingFile = true;
      _fileError = null;
    });

    try {
      String? pathToOpen;

      // Priorité 1 : chemin local direct (import depuis le téléphone)
      if (widget.document.hasLocalFile) {
        final exists = await fileExistsAtPath(widget.document.localPath!);
        if (exists) {
          pathToOpen = widget.document.localPath;
        }
      }

      // Priorité 2 : bytes en mémoire → écrire fichier temporaire
      if (pathToOpen == null && _hasBytes) {
        pathToOpen = await writeBytesToTempFile(
          _fileBytes!,
          widget.document.extension,
          widget.document.id,
        );
      }

      // Priorité 3 : charger bytes depuis localPath puis écrire temp
      if (pathToOpen == null && widget.document.hasLocalFile) {
        final bytes = await readFileBytes(widget.document.localPath!);
        if (bytes != null && bytes.isNotEmpty) {
          // Sauvegarder en cache pour la prochaine fois
          setState(() => _fileBytes = bytes);
          if (mounted) {
            // ignore: use_build_context_synchronously
            context.read<AppProvider>().cacheDocumentBytes(
                widget.document.id, bytes);
          }
          pathToOpen = await writeBytesToTempFile(
            bytes,
            widget.document.extension,
            widget.document.id,
          );
        }
      }

      if (pathToOpen != null && pathToOpen.isNotEmpty) {
        final result = await OpenFile.open(pathToOpen);
        if (!mounted) return;

        if (result.type == ResultType.done) {
          return; // Succès
        } else if (result.type == ResultType.noAppToOpen) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          _showNoAppDialog(context, pathToOpen);
        } else {
          setState(() {
            _fileError =
                '⚠️ ${result.message.isNotEmpty ? result.message : 'Impossible d\'ouvrir ce fichier (${widget.document.extension.toUpperCase()}).'}';
          });
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          _showOpenFileHelp(context);
        }
      } else if (widget.document.url != null) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        await _openUrl(context);
      } else {
        if (!mounted) return;
        setState(() {
          _fileError =
              'Fichier introuvable. Réimportez-le depuis l\'administration.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fileError = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoadingFile = false);
    }
  }

  // ─── Téléchargement web via data URL ────────────────────────
  Future<void> _downloadFileWeb(
      BuildContext context, Uint8List bytes, Document doc) async {
    try {
      final base64Data = base64Encode(bytes);
      final mimeType = _getMimeType(doc.extension);
      final dataUrl = 'data:$mimeType;base64,$base64Data';
      final uri = Uri.parse(dataUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Téléchargement : ${doc.titre}.${doc.extension}',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Fallback : ouvrir la visionneuse
        if (mounted) setState(() => _showViewer = true);
      }
    } catch (_) {
      if (mounted) setState(() => _showViewer = true);
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
      case 'py':
      case 'md':
      case 'csv':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // ─── Dialogue : aucune application installée ────────────────
  void _showNoAppDialog(BuildContext context, String tempFilePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF0D6E5C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucune app pour ${widget.document.extension.toUpperCase()}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le fichier est stocké dans l\'app mais aucune application externe n\'est disponible pour l\'ouvrir.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6E5C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 Solutions recommandées :',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (widget.document.isPdf)
                    const _HelpRow(
                        '• Installez "Adobe Acrobat Reader" sur Google Play'),
                  if (widget.document.isWord ||
                      widget.document.isExcel ||
                      widget.document.isPowerPoint)
                    const _HelpRow(
                        '• Installez "WPS Office" ou "Microsoft Office"'),
                  const _HelpRow(
                      '• Utilisez "Apprendre avec l\'IA" pour analyser ce document'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AILearnScreen(
                    document: widget.document,
                    preloadedBytes: _fileBytes,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Apprendre avec l\'IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A2580),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Snackbar d'aide pour erreurs d'ouverture ───────────────
  void _showOpenFileHelp(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Problème d\'ouverture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Utilisez "Apprendre avec l\'IA" pour analyser ce ${widget.document.extension.toUpperCase()}.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'IA ✨',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AILearnScreen(
                document: widget.document,
                preloadedBytes: _fileBytes,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final urlStr = widget.document.url;
    if (urlStr == null || urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir ce lien')),
        );
      }
    } catch (_) {}
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _chip(String label, IconData icon) {
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
          Icon(icon, size: 11, color: AppTheme.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: AppTheme.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
                  color: AppTheme.textDark)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMedium)),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton action ────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  final bool fullWidth;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: color, strokeWidth: 2))
                : Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget helper texte d'aide ────────────────────────────────
class _HelpRow extends StatelessWidget {
  final String text;
  const _HelpRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.5, color: AppTheme.textDark),
      ),
    );
  }
}
