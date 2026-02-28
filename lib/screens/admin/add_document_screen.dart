// lib/screens/admin/add_document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class AddDocumentScreen extends StatefulWidget {
  final Filiere filiere;
  final Niveau niveau;
  final Semestre semestre;
  final List<UE> ues;

  const AddDocumentScreen({
    super.key,
    required this.filiere,
    required this.niveau,
    required this.semestre,
    required this.ues,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  final _tailleController = TextEditingController();

  TypeDocument _selectedType = TypeDocument.cours;
  String? _selectedUEId;
  String? _selectedMatiereId;
  String _selectedExtension = 'pdf';

  final List<String> _extensions = ['pdf', 'docx', 'doc', 'xlsx', 'pptx', 'py', 'png', 'jpg'];

  @override
  void dispose() {
    _titreController.dispose();
    _urlController.dispose();
    _descController.dispose();
    _tailleController.dispose();
    super.dispose();
  }

  List<Matiere> get _matieres {
    if (_selectedUEId == null) return [];
    try {
      final ue = widget.ues.firstWhere((ue) => ue.id == _selectedUEId);
      return ue.matieres;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.white,
        title: const Text('Ajouter un document'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Localisation'),
              const SizedBox(height: 12),

              // Info niveau
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.filiere.nom} > ${widget.niveau.nom} > ${widget.semestre.nom}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // UE
              _buildLabel('Unité d\'Enseignement (UE)'),
              DropdownButtonFormField<String>(
                value: _selectedUEId,
                decoration: _inputDecoration('Sélectionner une UE'),
                items: widget.ues.map((ue) => DropdownMenuItem(
                  value: ue.id,
                  child: Text(ue.nom, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (val) => setState(() {
                  _selectedUEId = val;
                  _selectedMatiereId = null;
                }),
                validator: (v) => v == null ? 'Sélectionnez une UE' : null,
              ),

              const SizedBox(height: 16),

              // Matière
              _buildLabel('Matière'),
              DropdownButtonFormField<String>(
                value: _selectedMatiereId,
                decoration: _inputDecoration('Sélectionner une matière'),
                items: _matieres.map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.nom, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: _selectedUEId == null ? null : (val) => setState(() => _selectedMatiereId = val),
                validator: (v) => v == null ? 'Sélectionnez une matière' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Type de document'),
              const SizedBox(height: 12),

              // Type
              Wrap(
                spacing: 8,
                children: TypeDocument.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
                        ),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.white : AppTheme.textMedium,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Informations du fichier'),
              const SizedBox(height: 12),

              // Titre
              _buildLabel('Titre du document *'),
              TextFormField(
                controller: _titreController,
                decoration: _inputDecoration('Ex: Cours Probabilités S1 2024'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Le titre est requis' : null,
              ),

              const SizedBox(height: 16),

              // URL
              _buildLabel('Lien du document (URL Drive/SharePoint) *'),
              TextFormField(
                controller: _urlController,
                decoration: _inputDecoration('https://...'),
                keyboardType: TextInputType.url,
                validator: (v) =>
                    v == null || v.isEmpty ? 'L\'URL est requise' : null,
              ),

              const SizedBox(height: 16),

              // Extension
              _buildLabel('Format du fichier'),
              DropdownButtonFormField<String>(
                value: _selectedExtension,
                decoration: _inputDecoration(''),
                items: _extensions.map((ext) => DropdownMenuItem(
                  value: ext,
                  child: Text(ext.toUpperCase()),
                )).toList(),
                onChanged: (val) => setState(() => _selectedExtension = val ?? 'pdf'),
              ),

              const SizedBox(height: 16),

              // Description
              _buildLabel('Description (optionnel)'),
              TextFormField(
                controller: _descController,
                decoration: _inputDecoration('Brève description...'),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Taille
              _buildLabel('Taille du fichier (optionnel)'),
              TextFormField(
                controller: _tailleController,
                decoration: _inputDecoration('Ex: 2.5 MB'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addDocument,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter le document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TypeDocument t) {
    switch (t) {
      case TypeDocument.cours: return '📚 Cours';
      case TypeDocument.devoir: return '📝 Devoir';
      case TypeDocument.td: return '🔬 TD';
      case TypeDocument.complement: return '➕ Complément';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMedium),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint);
  }

  void _addDocument() {
    if (!_formKey.currentState!.validate()) return;

    final matiereName = _matieres
        .where((m) => m.id == _selectedMatiereId)
        .map((m) => m.nom)
        .firstOrNull ?? '';

    final document = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: _titreController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      type: _selectedType,
      url: _urlController.text.trim(),
      extension: _selectedExtension,
      taille: _tailleController.text.trim().isEmpty ? null : _tailleController.text.trim(),
      dateAjout: DateTime.now(),
      matiereId: _selectedMatiereId!,
      matiereName: matiereName,
      filiereId: widget.filiere.id,
      niveauId: widget.niveau.id,
    );

    context.read<AppProvider>().addDocument(widget.niveau.id, document);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.white),
            const SizedBox(width: 8),
            Text('"${document.titre}" ajouté avec succès'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
