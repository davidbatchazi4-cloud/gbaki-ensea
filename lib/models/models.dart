// lib/models/models.dart  — v2 (dynamique, stockage Hive)

class Filiere {
  final String id;
  final String nom;
  final String description;
  final String icon;
  final List<Niveau> niveaux;

  const Filiere({
    required this.id,
    required this.nom,
    required this.description,
    required this.icon,
    required this.niveaux,
  });
}

class Niveau {
  final String id;
  final String nom;
  final String filiereId;
  final List<Semestre> semestres;

  const Niveau({
    required this.id,
    required this.nom,
    required this.filiereId,
    this.semestres = const [],
  });
}

class Semestre {
  final String id;
  final String nom;

  const Semestre({required this.id, required this.nom});
}

// UE — maintenant entièrement dynamique
class UE {
  String id;
  String nom;
  String code;
  String niveauId;
  String semestreId;
  List<Matiere> matieres;

  UE({
    required this.id,
    required this.nom,
    required this.code,
    required this.niveauId,
    required this.semestreId,
    this.matieres = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'code': code,
        'niveauId': niveauId,
        'semestreId': semestreId,
        'matieres': matieres.map((m) => m.toJson()).toList(),
      };

  factory UE.fromJson(Map<String, dynamic> j) => UE(
        id: j['id'] as String,
        nom: j['nom'] as String,
        code: j['code'] as String,
        niveauId: j['niveauId'] as String,
        semestreId: j['semestreId'] as String,
        matieres: (j['matieres'] as List? ?? [])
            .map((m) => Matiere.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

// Matière — dynamique
class Matiere {
  String id;
  String nom;
  String ueId;
  String? enseignant;

  Matiere({
    required this.id,
    required this.nom,
    required this.ueId,
    this.enseignant,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'ueId': ueId,
        'enseignant': enseignant,
      };

  factory Matiere.fromJson(Map<String, dynamic> j) => Matiere(
        id: j['id'] as String,
        nom: j['nom'] as String,
        ueId: j['ueId'] as String,
        enseignant: j['enseignant'] as String?,
      );
}

enum TypeDocument { cours, devoir, td, complement }

extension TypeDocumentExt on TypeDocument {
  String get label {
    switch (this) {
      case TypeDocument.cours: return 'Cours';
      case TypeDocument.devoir: return 'Devoir';
      case TypeDocument.td: return 'TD';
      case TypeDocument.complement: return 'Complément';
    }
  }

  String get emoji {
    switch (this) {
      case TypeDocument.cours: return '📚';
      case TypeDocument.devoir: return '📝';
      case TypeDocument.td: return '🔬';
      case TypeDocument.complement: return '➕';
    }
  }
}

// Document — avec chemin local (import depuis téléphone)
class Document {
  final String id;
  final String titre;
  final String? description;
  final TypeDocument type;
  final String? localPath;   // chemin local après import
  final String? url;         // URL externe (optionnel)
  final String extension;
  final String? taille;
  final DateTime? dateAjout;
  final String matiereId;
  final String matiereName;
  final String ueId;
  final String filiereId;
  final String niveauId;
  final String semestreId;

  Document({
    required this.id,
    required this.titre,
    this.description,
    required this.type,
    this.localPath,
    this.url,
    required this.extension,
    this.taille,
    this.dateAjout,
    required this.matiereId,
    required this.matiereName,
    required this.ueId,
    required this.filiereId,
    required this.niveauId,
    required this.semestreId,
  });

  bool get isPdf => extension.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension.toLowerCase());
  bool get isWord => ['doc', 'docx'].contains(extension.toLowerCase());
  bool get isExcel => ['xls', 'xlsx'].contains(extension.toLowerCase());
  bool get isPowerPoint => ['ppt', 'pptx'].contains(extension.toLowerCase());
  bool get isPython => extension.toLowerCase() == 'py';
  bool get hasLocalFile => localPath != null && localPath!.isNotEmpty;
  String get typeLabel => type.label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'type': type.index,
        'localPath': localPath,
        'url': url,
        'extension': extension,
        'taille': taille,
        'dateAjout': dateAjout?.toIso8601String(),
        'matiereId': matiereId,
        'matiereName': matiereName,
        'ueId': ueId,
        'filiereId': filiereId,
        'niveauId': niveauId,
        'semestreId': semestreId,
      };

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as String,
        titre: j['titre'] as String,
        description: j['description'] as String?,
        type: TypeDocument.values[j['type'] as int],
        localPath: j['localPath'] as String?,
        url: j['url'] as String?,
        extension: j['extension'] as String,
        taille: j['taille'] as String?,
        dateAjout: j['dateAjout'] != null ? DateTime.tryParse(j['dateAjout'] as String) : null,
        matiereId: j['matiereId'] as String,
        matiereName: j['matiereName'] as String,
        ueId: j['ueId'] as String,
        filiereId: j['filiereId'] as String,
        niveauId: j['niveauId'] as String,
        semestreId: j['semestreId'] as String,
      );
}

// Modèle IA
class AIContent {
  final String resume;
  final List<QuizQuestion> quiz;
  final List<FicheRevision> fiches;
  final String explicationSimple;
  final String explicationDetaillee;

  const AIContent({
    required this.resume,
    required this.quiz,
    required this.fiches,
    required this.explicationSimple,
    required this.explicationDetaillee,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explication;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explication,
  });
}

class FicheRevision {
  final String titre;
  final String contenu;
  final List<String> pointsCles;

  const FicheRevision({
    required this.titre,
    required this.contenu,
    required this.pointsCles,
  });
}

// Enum rôle utilisateur
enum UserRole { user, admin }
