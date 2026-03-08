// lib/models/app_data.dart
// Structure complète de l'ENSEA avec données initiales

import 'models.dart';

class AppData {
  static const List<Filiere> filieres = [
    Filiere(
      id: 'as',
      nom: 'AS',
      description: 'Actuariat & Statistique',
      icon: '📊',
      niveaux: [
        Niveau(id: 'as1', nom: 'AS1', filiereId: 'as', semestres: [
          Semestre(id: 'as1_s1', nom: 'Semestre 1'),
          Semestre(id: 'as1_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'as2', nom: 'AS2', filiereId: 'as', semestres: [
          Semestre(id: 'as2_s1', nom: 'Semestre 1'),
          Semestre(id: 'as2_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'as3_ds', nom: 'AS3 - Data Science', filiereId: 'as', semestres: [
          Semestre(id: 'as3_ds_s1', nom: 'Semestre 1'),
          Semestre(id: 'as3_ds_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'as3_se', nom: 'AS3 - Stat Éco', filiereId: 'as', semestres: [
          Semestre(id: 'as3_se_s1', nom: 'Semestre 1'),
          Semestre(id: 'as3_se_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'as3_ip', nom: 'AS3 - Ingénierie Projet', filiereId: 'as', semestres: [
          Semestre(id: 'as3_ip_s1', nom: 'Semestre 1'),
          Semestre(id: 'as3_ip_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'as3_ss', nom: 'AS3 - Statistiques Sociales', filiereId: 'as', semestres: [
          Semestre(id: 'as3_ss_s1', nom: 'Semestre 1'),
          Semestre(id: 'as3_ss_s2', nom: 'Semestre 2'),
        ]),
      ],
    ),
    Filiere(
      id: 'ise',
      nom: 'ISE',
      description: 'Ingénieur Statisticien Économiste',
      icon: '📈',
      niveaux: [
        Niveau(id: 'ise1_eco', nom: 'ISE1 - Économie', filiereId: 'ise', semestres: [
          Semestre(id: 'ise1_eco_s1', nom: 'Semestre 1'),
          Semestre(id: 'ise1_eco_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ise1_math', nom: 'ISE1 - Mathématiques', filiereId: 'ise', semestres: [
          Semestre(id: 'ise1_math_s1', nom: 'Semestre 1'),
          Semestre(id: 'ise1_math_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ise2', nom: 'ISE2', filiereId: 'ise', semestres: [
          Semestre(id: 'ise2_s1', nom: 'Semestre 1'),
          Semestre(id: 'ise2_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ise3', nom: 'ISE3', filiereId: 'ise', semestres: [
          Semestre(id: 'ise3_s1', nom: 'Semestre 1'),
          Semestre(id: 'ise3_s2', nom: 'Semestre 2'),
        ]),
      ],
    ),
    Filiere(
      id: 'ips',
      nom: 'IPS',
      description: 'Ingénieur des Travaux Statistiques',
      icon: '🔢',
      niveaux: [
        Niveau(id: 'ips_math1', nom: 'IPS Math - Niveau 1', filiereId: 'ips', semestres: [
          Semestre(id: 'ips_math1_s1', nom: 'Semestre 1'),
          Semestre(id: 'ips_math1_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ips_math2', nom: 'IPS Math - Niveau 2', filiereId: 'ips', semestres: [
          Semestre(id: 'ips_math2_s1', nom: 'Semestre 1'),
          Semestre(id: 'ips_math2_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ips_eco1', nom: 'IPS Éco - Niveau 1', filiereId: 'ips', semestres: [
          Semestre(id: 'ips_eco1_s1', nom: 'Semestre 1'),
          Semestre(id: 'ips_eco1_s2', nom: 'Semestre 2'),
        ]),
        Niveau(id: 'ips_eco2', nom: 'IPS Éco - Niveau 2', filiereId: 'ips', semestres: [
          Semestre(id: 'ips_eco2_s1', nom: 'Semestre 1'),
          Semestre(id: 'ips_eco2_s2', nom: 'Semestre 2'),
        ]),
      ],
    ),
  ];
}
