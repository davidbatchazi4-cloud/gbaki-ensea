// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDqPNmrMKrEe_41NNxVaIimjRH9YS7k90s';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  Future<AIContent> analyzeDocument({
    required String documentTitle,
    required String documentType,
    String? documentContent,
    String? documentUrl,
  }) async {
    final prompt = '''
Tu es un assistant pédagogique expert pour des étudiants en statistiques et économie à l'ENSEA (École Nationale Supérieure de Statistique et d'Économie Appliquée) d'Abidjan.

Document à analyser : "$documentTitle" (Type: $documentType)
${documentContent != null ? 'Contenu : $documentContent' : ''}

Génère en JSON valide UNIQUEMENT (sans markdown, sans bloc de code) la structure suivante :
{
  "resume": "Résumé complet et clair du document en 3-4 paragraphes",
  "explication_simple": "Explication simplifiée des concepts clés, comme si tu expliquais à un lycéen",
  "explication_detaillee": "Explication détaillée et approfondie avec tous les concepts, formules et théorèmes importants",
  "quiz": [
    {
      "question": "Question de compréhension",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0,
      "explication": "Pourquoi cette réponse est correcte"
    }
  ],
  "fiches": [
    {
      "titre": "Titre de la fiche",
      "contenu": "Contenu de la fiche de révision",
      "points_cles": ["Point clé 1", "Point clé 2", "Point clé 3"]
    }
  ]
}

Génère 5 questions de quiz et 3 fiches de révision. Réponds UNIQUEMENT avec le JSON, sans aucun autre texte.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 4096,
          },
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        // Nettoyer la réponse
        String cleanText = text.trim();
        if (cleanText.startsWith('```')) {
          cleanText = cleanText.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '');
        }
        
        final jsonData = jsonDecode(cleanText) as Map<String, dynamic>;
        return _parseAIContent(jsonData);
      } else {
        throw Exception('Erreur API Gemini: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackContent(documentTitle);
    }
  }

  Future<List<Document>> searchDocuments({
    required String query,
    required List<Document> allDocuments,
  }) async {
    if (query.isEmpty) return allDocuments;

    final prompt = '''
Tu es un moteur de recherche intelligent pour une bibliothèque de documents académiques.

Requête de l'étudiant : "$query"

Liste des documents disponibles (format: id|titre|type|matiere):
${allDocuments.map((d) => '${d.id}|${d.titre}|${d.typeLabel}|${d.matiereName}').join('\n')}

Retourne UNIQUEMENT une liste JSON d'IDs de documents pertinents, triés par pertinence :
["id1", "id2", "id3"]

Réponds UNIQUEMENT avec le JSON.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 512,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        String cleanText = text.trim().replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '');
        
        final ids = (jsonDecode(cleanText) as List).cast<String>();
        return allDocuments.where((d) => ids.contains(d.id)).toList();
      }
    } catch (e) {
      // Fallback: recherche locale simple
    }

    // Recherche locale par mots-clés
    final queryLower = query.toLowerCase();
    return allDocuments.where((doc) {
      return doc.titre.toLowerCase().contains(queryLower) ||
          doc.matiereName.toLowerCase().contains(queryLower) ||
          doc.typeLabel.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<String> askQuestion({
    required String question,
    required String documentTitle,
    String? context,
  }) async {
    final prompt = '''
Tu es un tuteur pédagogique pour des étudiants de l'ENSEA d'Abidjan (statistiques et économie).
Document de référence : "$documentTitle"
${context != null ? 'Contexte : $context' : ''}

Question de l'étudiant : "$question"

Donne une réponse claire, précise et pédagogique en français. Si la question ne concerne pas le document, réponds quand même de manière utile.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 2048,
          },
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
    } catch (e) {
      return 'Désolé, je n\'ai pas pu répondre à votre question. Vérifiez votre connexion internet.';
    }
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  AIContent _parseAIContent(Map<String, dynamic> json) {
    final quizList = (json['quiz'] as List? ?? []).map((q) {
      final options = (q['options'] as List).cast<String>();
      return QuizQuestion(
        question: q['question'] as String? ?? '',
        options: options,
        correctIndex: q['correct_index'] as int? ?? 0,
        explication: q['explication'] as String? ?? '',
      );
    }).toList();

    final fichesList = (json['fiches'] as List? ?? []).map((f) {
      final pointsCles = (f['points_cles'] as List? ?? []).cast<String>();
      return FicheRevision(
        titre: f['titre'] as String? ?? '',
        contenu: f['contenu'] as String? ?? '',
        pointsCles: pointsCles,
      );
    }).toList();

    return AIContent(
      resume: json['resume'] as String? ?? '',
      quiz: quizList,
      fiches: fichesList,
      explicationSimple: json['explication_simple'] as String? ?? '',
      explicationDetaillee: json['explication_detaillee'] as String? ?? '',
    );
  }

  AIContent _getFallbackContent(String title) {
    return AIContent(
      resume: 'Résumé de "$title" - L\'analyse IA n\'est pas disponible pour le moment. Vérifiez votre connexion internet.',
      quiz: [
        QuizQuestion(
          question: 'Question sur "$title"',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctIndex: 0,
          explication: 'L\'explication sera disponible une fois la connexion rétablie.',
        ),
      ],
      fiches: [
        FicheRevision(
          titre: 'Fiche de révision',
          contenu: 'Contenu non disponible.',
          pointsCles: ['Reconnectez-vous à internet pour accéder aux fiches'],
        ),
      ],
      explicationSimple: 'Explication non disponible.',
      explicationDetaillee: 'Explication détaillée non disponible.',
    );
  }
}
