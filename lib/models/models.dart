// lib/models/models.dart

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
  final List<UE> ues;

  const Semestre({
    required this.id,
    required this.nom,
    this.ues = const [],
  });
}

class UE {
  final String id;
  final String nom;
  final String code;
  final List<Matiere> matieres;

  const UE({
    required this.id,
    required this.nom,
    required this.code,
    this.matieres = const [],
  });
}

class Matiere {
  final String id;
  final String nom;
  final String? enseignant;
  final List<Document> cours;
  final List<Document> devoirs;
  final List<Document> td;
  final List<Document> complements;

  const Matiere({
    required this.id,
    required this.nom,
    this.enseignant,
    this.cours = const [],
    this.devoirs = const [],
    this.td = const [],
    this.complements = const [],
  });

  List<Document> get allDocuments => [...cours, ...devoirs, ...td, ...complements];
}

enum TypeDocument { cours, devoir, td, complement }

class Document {
  final String id;
  final String titre;
  final String? description;
  final TypeDocument type;
  final String url;
  final String extension;
  final String? taille;
  final DateTime? dateAjout;
  final String matiereId;
  final String matiereName;
  final String filiereId;
  final String niveauId;

  const Document({
    required this.id,
    required this.titre,
    this.description,
    required this.type,
    required this.url,
    required this.extension,
    this.taille,
    this.dateAjout,
    required this.matiereId,
    required this.matiereName,
    required this.filiereId,
    required this.niveauId,
  });

  String get typeLabel {
    switch (type) {
      case TypeDocument.cours:
        return 'Cours';
      case TypeDocument.devoir:
        return 'Devoir';
      case TypeDocument.td:
        return 'TD';
      case TypeDocument.complement:
        return 'Complément';
    }
  }

  bool get isPdf => extension.toLowerCase() == 'pdf';
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif'].contains(extension.toLowerCase());
  bool get isWord =>
      ['doc', 'docx'].contains(extension.toLowerCase());
  bool get isExcel =>
      ['xls', 'xlsx'].contains(extension.toLowerCase());
  bool get isPowerPoint =>
      ['ppt', 'pptx'].contains(extension.toLowerCase());
  bool get isPython =>
      extension.toLowerCase() == 'py';
}

// Modèle de contenu IA
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
