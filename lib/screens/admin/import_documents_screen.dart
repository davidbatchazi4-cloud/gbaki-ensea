// lib/screens/admin/import_documents_screen.dart — v3 (Web + Mobile compatible)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/file_import_service.dart';

class ImportDocumentsScreen extends StatefulWidget {
  final Filiere filiere;
  final Niveau niveau;
  final Semestre semestre;

  const ImportDocumentsScreen({
    super.key,
    required this.filiere,
    required this.niveau,
    required this.semestre,
  });

  @override
  State<ImportDocumentsScreen> createState() => _ImportDocumentsScreenState();
}

class _ImportDocumentsScreenState extends State<ImportDocumentsScreen> {
  final FileImportService _importSvc = FileImportService();

  final List<_PendingDoc> _pendingDocs = [];
  bool _isImporting = false;
  bool _isSaving = false;
  String? _importError;

  Color get _color {
    switch (widget.filiere.id) {
      case 'as': return const Color(0xFF1B4B8A);
      case 'ise': return const Color(0xFF0D6E5C);
      case 'ips': return const Color(0xFF5B2D8A);
      default: return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final ues = provider.getUEsForSemestre(widget.niveau.id, widget.semestre.id);

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.white,
        title: const Text('Importer des documents'),
        elevation: 0,
        actions: [
          if (_pendingDocs.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : () => _saveAll(context, provider),
              icon: const Icon(Icons.save_outlined, color: AppTheme.white, size: 20),
              label: Text(
                'Enregistrer (${_pendingDocs.length})',
                style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau contexte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.accentGold.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.filiere.nom} › ${widget.niveau.nom} › ${widget.semestre.nom}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),

          // Message d'erreur si présent
          if (_importError != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_importError!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _importError = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Boutons d'import
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ImportButton(
                        icon: Icons.insert_drive_file_outlined,
                        label: 'Un fichier',
                        subtitle: 'PDF, Word, Excel…',
                        color: _color,
                        isLoading: _isImporting,
                        onTap: _pickSingle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImportButton(
                        icon: Icons.file_copy_outlined,
                        label: 'Plusieurs fichiers',
                        subtitle: 'Sélection multiple',
                        color: const Color(0xFF0D6E5C),
                        isLoading: _isImporting,
                        onTap: _pickMultiple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ImportButton(
                  icon: Icons.folder_open_outlined,
                  label: 'Dossier entier',
                  subtitle: 'Sélectionner tous les fichiers d\'un dossier',
                  color: const Color(0xFF5B2D8A),
                  isLoading: _isImporting,
                  onTap: _pickFolder,
                  fullWidth: true,
                ),
              ],
            ),
          ),

          // Formats supportés
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['PDF', 'DOCX', 'XLSX', 'PPTX', 'PY', 'TXT', 'PNG', 'JPG', 'ZIP']
                  .map((ext) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _color.withValues(alpha: 0.2)),
                        ),
                        child: Text(ext,
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold, color: _color)),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),
          Divider(color: AppTheme.lightGray, height: 1),

          // Liste des fichiers en attente
          if (_pendingDocs.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _pendingDocs.length,
                itemBuilder: (ctx, i) => _PendingDocCard(
                  pending: _pendingDocs[i],
                  ues: ues,
                  color: _color,
                  onRemove: () => setState(() => _pendingDocs.removeAt(i)),
                  onUpdate: (updated) => setState(() => _pendingDocs[i] = updated),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _pendingDocs.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.success,
              foregroundColor: AppTheme.white,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSaving
                  ? 'Enregistrement...'
                  : 'Enregistrer ${_pendingDocs.length} fichier(s)'),
              onPressed: _isSaving ? null : () => _saveAll(context, provider),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.upload_file, size: 56, color: _color.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            const Text('Aucun fichier sélectionné',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur un bouton ci-dessus\npour importer vos documents',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Astuce : Pour importer un dossier entier,\nutilisez "Dossier entier" et sélectionnez\ntous les fichiers avec Ctrl+A ou Cmd+A',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIONS D'IMPORT ─────────────────────────────────────────

  Future<void> _pickSingle() async {
    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final file = await _importSvc.pickSingleFile();
      if (file != null) {
        setState(() => _pendingDocs.add(_PendingDoc.fromImported(file)));
      }
    } catch (e) {
      setState(() => _importError = 'Erreur lors de la sélection : $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _pickMultiple() async {
    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final files = await _importSvc.pickMultipleFiles();
      if (files.isNotEmpty) {
        setState(() => _pendingDocs.addAll(files.map(_PendingDoc.fromImported)));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${files.length} fichier(s) ajouté(s)'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      setState(() => _importError = 'Erreur lors de la sélection : $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _pickFolder() async {
    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final files = await _importSvc.pickFolder();
      if (files.isNotEmpty) {
        setState(() => _pendingDocs.addAll(files.map(_PendingDoc.fromImported)));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${files.length} fichier(s) importé(s)'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Aucun fichier compatible sélectionné'),
            backgroundColor: AppTheme.accentGold,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      setState(() => _importError = 'Erreur lors de la sélection : $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _saveAll(BuildContext context, AppProvider provider) async {
    // Vérifier que tous les docs ont UE + matière assignés
    final incomplete = _pendingDocs.where((d) => d.ueId == null || d.matiereId == null).toList();
    if (incomplete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${incomplete.length} fichier(s) sans UE/matière assignée'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);

    final ts = DateTime.now();
    // Créer docs et collecter bytes
    final docs = <Document>[];
    final bytesMap = <String, Uint8List>{};

    for (int i = 0; i < _pendingDocs.length; i++) {
      final p = _pendingDocs[i];
      final docId = 'doc_${ts.millisecondsSinceEpoch}_$i';

      docs.add(Document(
        id: docId,
        titre: p.titre,
        description: p.description,
        type: p.type,
        localPath: p.file.localPath,
        extension: p.file.extension,
        taille: p.file.size,
        dateAjout: ts,
        matiereId: p.matiereId!,
        matiereName: p.matiereName ?? '',
        ueId: p.ueId!,
        filiereId: widget.filiere.id,
        niveauId: widget.niveau.id,
        semestreId: widget.semestre.id,
      ));

      // Sauvegarder les bytes pour lecture hors-ligne + IA
      if (p.file.bytes != null && p.file.bytes!.isNotEmpty) {
        bytesMap[docId] = p.file.bytes!;
      }
    }

    await provider.addDocuments(docs, bytesMap: bytesMap);
    setState(() => _isSaving = false);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${docs.length} document(s) enregistré(s) avec succès !'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── MODÈLE INTERNE ──────────────────────────────────────────────
class _PendingDoc {
  final ImportedFile file;
  String titre;
  String? description;
  TypeDocument type;
  String? ueId;
  String? matiereId;
  String? matiereName;

  _PendingDoc({
    required this.file,
    required this.titre,
    this.description,
    this.type = TypeDocument.cours,
    this.ueId,
    this.matiereId,
    this.matiereName,
  });

  factory _PendingDoc.fromImported(ImportedFile f) => _PendingDoc(
        file: f,
        titre: f.name,
        type: TypeDocument.cours,
      );

  _PendingDoc copyWith({
    String? titre,
    String? description,
    TypeDocument? type,
    String? ueId,
    String? matiereId,
    String? matiereName,
  }) =>
      _PendingDoc(
        file: file,
        titre: titre ?? this.titre,
        description: description ?? this.description,
        type: type ?? this.type,
        ueId: ueId ?? this.ueId,
        matiereId: matiereId ?? this.matiereId,
        matiereName: matiereName ?? this.matiereName,
      );
}

// ─── CARTE FICHIER EN ATTENTE ────────────────────────────────────
class _PendingDocCard extends StatefulWidget {
  final _PendingDoc pending;
  final List<UE> ues;
  final Color color;
  final VoidCallback onRemove;
  final Function(_PendingDoc) onUpdate;

  const _PendingDocCard({
    required this.pending,
    required this.ues,
    required this.color,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_PendingDocCard> createState() => _PendingDocCardState();
}

class _PendingDocCardState extends State<_PendingDocCard> {
  bool _expanded = true;

  IconData get _fileIcon {
    switch (widget.pending.file.extension.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'ppt':
      case 'pptx': return Icons.slideshow;
      case 'py': return Icons.code;
      case 'png':
      case 'jpg':
      case 'jpeg': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color get _fileColor {
    switch (widget.pending.file.extension.toLowerCase()) {
      case 'pdf': return const Color(0xFFE74C3C);
      case 'doc':
      case 'docx': return const Color(0xFF2B5DBB);
      case 'xls':
      case 'xlsx': return const Color(0xFF1D6F42);
      case 'ppt':
      case 'pptx': return const Color(0xFFD04523);
      case 'py': return const Color(0xFF3776AB);
      default: return AppTheme.primaryBlue;
    }
  }

  List<Matiere> get _matieres {
    if (widget.pending.ueId == null) return [];
    try {
      return widget.ues.firstWhere((u) => u.id == widget.pending.ueId).matieres;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pending;
    final isConfigured = p.ueId != null && p.matiereId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfigured
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.lightGray,
          width: isConfigured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _fileColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_fileIcon, color: _fileColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.titre,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${p.file.extension.toUpperCase()} • ${p.file.size}'
                          '${isConfigured ? ' • ✅ Configuré' : ' • ⚠️ À configurer'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isConfigured ? AppTheme.success : AppTheme.accentGold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppTheme.error),
                    onPressed: widget.onRemove,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textLight, size: 20),
                ],
              ),
            ),
          ),

          // Formulaire
          if (_expanded) ...[
            Divider(color: AppTheme.lightGray, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  // Titre
                  TextFormField(
                    initialValue: p.titre,
                    decoration: const InputDecoration(
                        labelText: 'Titre du document',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => widget.onUpdate(p.copyWith(titre: v)),
                  ),
                  const SizedBox(height: 10),

                  // Type de document
                  Row(
                    children: TypeDocument.values.map((t) {
                      final sel = p.type == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onUpdate(p.copyWith(type: t)),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: t != TypeDocument.values.last ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? widget.color : AppTheme.offWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: sel ? widget.color : AppTheme.lightGray),
                            ),
                            child: Column(
                              children: [
                                Text(t.emoji, style: const TextStyle(fontSize: 14)),
                                Text(t.label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? AppTheme.white : AppTheme.textMedium)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Sélection UE
                  widget.ues.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_outlined,
                                  color: AppTheme.error, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aucune UE disponible — créez-en d\'abord dans "Gérer les UEs"',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: p.ueId,
                          isDense: true,
                          decoration: const InputDecoration(
                              labelText: 'UE *',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10)),
                          items: widget.ues
                              .map((ue) => DropdownMenuItem(
                                    value: ue.id,
                                    child: Text('${ue.code} — ${ue.nom}',
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) => widget.onUpdate(
                              p.copyWith(ueId: v, matiereId: null)),
                        ),
                  const SizedBox(height: 10),

                  // Sélection Matière
                  _matieres.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.lightGray),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.textLight, size: 16),
                              SizedBox(width: 8),
                              Text('Sélectionnez une UE d\'abord',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight)),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _matieres.any((m) => m.id == p.matiereId)
                              ? p.matiereId
                              : null,
                          isDense: true,
                          decoration: const InputDecoration(
                              labelText: 'Matière *',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10)),
                          items: _matieres
                              .map((m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.nom,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            final matName =
                                _matieres.firstWhere((m) => m.id == v).nom;
                            widget.onUpdate(
                                p.copyWith(matiereId: v, matiereName: matName));
                          },
                        ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── BOUTON D'IMPORT ─────────────────────────────────────────────
class _ImportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ImportButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: fullWidth ? 14 : 18,
        ),
        decoration: BoxDecoration(
          color: isLoading
              ? color.withValues(alpha: 0.04)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: fullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoading
                      ? SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: color, strokeWidth: 2))
                      : Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: color)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isLoading
                      ? SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: color, strokeWidth: 2))
                      : Icon(icon, color: color, size: 26),
                  const SizedBox(height: 8),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: color),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 10, color: color.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}
