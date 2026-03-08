// lib/services/gemini_service.dart — v5 : gemini-2.5-flash prioritaire + meilleure extraction
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDqPNmrMKrEe_41NNxVaIimjRH9YS7k90s';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Ordre de priorité : gemini-2.5-flash testé et fonctionnel en premier
  // Fallback vers les modèles moins récents si quota épuisé
  static const List<String> _models = [
    'gemini-2.5-flash',         // ✅ Testé et fonctionnel — PRIORITAIRE
    'gemini-2.5-flash-lite',    // Fallback 1
    'gemini-2.0-flash',         // Fallback 2
    'gemini-2.0-flash-lite',    // Fallback 3
    'gemini-flash-latest',      // Fallback 4
  ];

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // ─── Appel API avec rotation automatique des modèles ──────────
  Future<Map<String, dynamic>?> _callGemini({
    required String prompt,
    double temperature = 0.5,
    int maxOutputTokens = 8192,
  }) async {
    for (final model in _models) {
      try {
        final url = '$_baseUrl/$model:generateContent?key=$_apiKey';
        final response = await http.post(
          Uri.parse(url),
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
              'temperature': temperature,
              'maxOutputTokens': maxOutputTokens,
            },
          }),
        ).timeout(const Duration(seconds: 90));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          // Quota épuisé ou surcharge — essayer le prochain modèle
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else if (response.statusCode == 404) {
          // Modèle non trouvé — essayer le suivant
          continue;
        } else {
          continue;
        }
      } catch (_) {
        continue;
      }
    }
    return null; // Tous les modèles ont échoué
  }

  String _extractText(Map<String, dynamic> data) {
    try {
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (_) {
      return '';
    }
  }

  // ─── Extraction de texte depuis les bytes du fichier ──────────
  String extractTextFromBytes(Uint8List bytes, String extension) {
    try {
      final ext = extension.toLowerCase();
      if (['txt', 'py', 'md', 'csv', 'json', 'html', 'xml', 'log'].contains(ext)) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      if (ext == 'pdf') {
        return _extractPdfText(bytes);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  String _extractPdfText(Uint8List bytes) {
    try {
      // Méthode 1 : Extraction des objets texte PDF (entre parenthèses dans les flux BT/ET)
      final raw = latin1.decode(bytes.toList());

      final buffer = StringBuffer();

      // Chercher les blocs BT...ET (begin text / end text)
      final btEtRegex = RegExp(r'BT(.*?)ET', dotAll: true);
      for (final match in btEtRegex.allMatches(raw)) {
        final block = match.group(1) ?? '';

        // Extraire les chaînes entre parenthèses ()
        final parenRegex = RegExp(r'\(([^)]{1,200})\)');
        for (final pMatch in parenRegex.allMatches(block)) {
          final s = pMatch.group(1) ?? '';
          if (_isReadableText(s)) {
            buffer.write('$s ');
          }
        }
      }

      String result = buffer.toString().trim();

      // Méthode 2 si peu de texte extrait : méthode basique ASCII
      if (result.length < 100) {
        result = _extractPdfBasic(bytes);
      }

      return result.length > 10000 ? result.substring(0, 10000) : result;
    } catch (_) {
      return _extractPdfBasic(bytes);
    }
  }

  bool _isReadableText(String s) {
    if (s.length < 2) return false;
    int readableCount = 0;
    for (final c in s.runes) {
      // Caractères imprimables (ASCII étendu + accents français)
      if ((c >= 32 && c <= 126) || (c >= 160 && c <= 255)) {
        readableCount++;
      }
    }
    return readableCount > s.length * 0.6;
  }

  String _extractPdfBasic(Uint8List bytes) {
    try {
      final content = String.fromCharCodes(
        bytes.where((b) => b >= 32 && b <= 126).toList(),
      );
      final buffer = StringBuffer();
      final words = content.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 2 &&
            !word.startsWith('/') &&
            !word.contains('<') &&
            !word.contains('>') &&
            !word.contains('(') &&
            !RegExp(r'^[0-9\.\-]+$').hasMatch(word)) {
          buffer.write('$word ');
        }
      }
      final extracted = buffer.toString().trim();
      return extracted.length > 8000 ? extracted.substring(0, 8000) : extracted;
    } catch (_) {
      return '';
    }
  }

  // ─── Analyse complète du document ─────────────────────────────
  Future<AIContent> analyzeDocument({
    required String documentTitle,
    required String documentType,
    String? extractedText,
    Uint8List? fileBytes,
    String? fileExtension,
  }) async {
    String contentForAI = extractedText ?? '';
    if (contentForAI.isEmpty && fileBytes != null && fileExtension != null) {
      contentForAI = extractTextFromBytes(fileBytes, fileExtension);
    }

    final hasContent = contentForAI.isNotEmpty && contentForAI.length > 50;
    final contentPreview = hasContent
        ? (contentForAI.length > 8000
            ? contentForAI.substring(0, 8000)
            : contentForAI)
        : null;

    final prompt = """Tu es GBAKI IA, un assistant pédagogique expert pour les étudiants en statistiques, économie et mathématiques à l'ENSEA d'Abidjan (Côte d'Ivoire). Tu dois analyser le document et produire un contenu pédagogique riche.

Document : "$documentTitle"
Type : $documentType
${contentPreview != null ? '\n=== CONTENU DU DOCUMENT ===\n$contentPreview\n=== FIN ===' : '\n[Document sans texte extractible — base-toi sur le titre et le type pour générer du contenu pertinent]'}

IMPORTANT : Génère UNIQUEMENT du JSON valide (aucun texte avant ou après, aucun markdown, aucun backtick).

Structure JSON requise :
{
  "resume": "Résumé complet en 4-5 paragraphes avec les concepts clés, formules importantes et méthodes. Minimum 300 mots.",
  "explication_simple": "Explication accessible à un débutant, avec analogies et exemples concrets de la vie quotidienne. Minimum 150 mots.",
  "explication_detaillee": "Explication technique approfondie avec formules mathématiques (en notation LaTeX simple), démonstrations et applications. Minimum 200 mots.",
  "quiz": [
    {"question": "Question claire et précise", "options": ["Option A", "Option B", "Option C", "Option D"], "correct_index": 0, "explication": "Explication détaillée de la bonne réponse"},
    ... (5 questions au total, de difficulté croissante)
  ],
  "fiches": [
    {"titre": "Titre court", "contenu": "Explication détaillée du concept (minimum 100 mots)", "points_cles": ["Point clé 1", "Point clé 2", "Point clé 3"]},
    ... (4 fiches au total)
  ]
}

Génère exactement 5 questions de quiz et 4 fiches de révision. JSON UNIQUEMENT, sans aucun texte avant ou après.""";

    try {
      final data = await _callGemini(
        prompt: prompt,
        temperature: 0.3,
        maxOutputTokens: 8192,
      );

      if (data != null) {
        String text = _extractText(data).trim();
        // Nettoyer le JSON
        text = text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start >= 0 && end > start) {
          text = text.substring(start, end + 1);
          try {
            final jsonData = jsonDecode(text) as Map<String, dynamic>;
            return _parseAIContent(jsonData);
          } catch (_) {}
        }
      }
    } catch (_) {}

    return _getFallbackContent(documentTitle);
  }

  // ─── Chat avec contexte complet du document ───────────────────
  Future<String> askQuestion({
    required String question,
    required String documentTitle,
    String? documentType,
    String? extractedText,
    Uint8List? fileBytes,
    String? fileExtension,
    List<Map<String, String>>? chatHistory,
  }) async {
    String contentForAI = extractedText ?? '';
    if (contentForAI.isEmpty && fileBytes != null && fileExtension != null) {
      contentForAI = extractTextFromBytes(fileBytes, fileExtension);
    }

    final hasContent = contentForAI.isNotEmpty && contentForAI.length > 50;

    final historyText = chatHistory != null && chatHistory.isNotEmpty
        ? chatHistory
            .map((m) =>
                '${m['role'] == 'user' ? 'Étudiant' : 'IA'}: ${m['content']}')
            .join('\n')
        : '';

    final prompt = '''Tu es GBAKI IA, tuteur pédagogique pour les étudiants de l'ENSEA d'Abidjan (statistiques, économie, mathématiques). Tu parles français, tu es clair et pédagogique.

Document : "$documentTitle"${documentType != null ? ' ($documentType)' : ''}
${hasContent ? '\n=== CONTENU ===\n${contentForAI.length > 5000 ? contentForAI.substring(0, 5000) : contentForAI}\n=== FIN ===' : ''}
${historyText.isNotEmpty ? '\n=== HISTORIQUE ===\n$historyText\n=== FIN ===' : ''}

Question : "$question"

Réponds en français, de façon claire et pédagogique. Si besoin, utilise des formules mathématiques. Sois concis mais complet.''';

    try {
      final data = await _callGemini(
        prompt: prompt,
        temperature: 0.6,
        maxOutputTokens: 2048,
      );

      if (data != null) {
        final text = _extractText(data);
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}

    return '⚠️ Impossible de contacter l\'IA pour le moment.\n\n**Causes possibles :**\n- Quota API dépassé (limite gratuite atteinte)\n- Problème de connexion internet\n\n**Solution :** Réessayez dans quelques minutes ou vérifiez votre connexion internet.';
  }

  // ─── Recherche intelligente de documents ──────────────────────
  Future<List<Document>> searchDocuments({
    required String query,
    required List<Document> allDocuments,
  }) async {
    if (query.isEmpty) return allDocuments;

    final prompt = '''Moteur de recherche pour bibliothèque académique ENSEA.
Requête : "$query"
Documents disponibles (id|titre|type|matiere) :
${allDocuments.map((d) => '${d.id}|${d.titre}|${d.typeLabel}|${d.matiereName}').join('\n')}
Retourne UNIQUEMENT une liste JSON des IDs pertinents triés par pertinence : ["id1","id2"]
JSON uniquement, rien d'autre.''';

    try {
      final data = await _callGemini(
        prompt: prompt,
        temperature: 0.1,
        maxOutputTokens: 512,
      );

      if (data != null) {
        String text = _extractText(data).trim();
        text = text
            .replaceAll(RegExp(r'```json?\s*'), '')
            .replaceAll('```', '')
            .trim();
        final start = text.indexOf('[');
        final end = text.lastIndexOf(']');
        if (start >= 0 && end > start) {
          text = text.substring(start, end + 1);
          final ids = (jsonDecode(text) as List).cast<String>();
          return allDocuments.where((d) => ids.contains(d.id)).toList();
        }
      }
    } catch (_) {}

    // Fallback recherche locale
    final q = query.toLowerCase();
    return allDocuments
        .where((d) =>
            d.titre.toLowerCase().contains(q) ||
            d.matiereName.toLowerCase().contains(q) ||
            d.typeLabel.toLowerCase().contains(q))
        .toList();
  }

  // ─── Parsing ─────────────────────────────────────────────────
  AIContent _parseAIContent(Map<String, dynamic> json) {
    final quizList = (json['quiz'] as List? ?? [])
        .map((q) => QuizQuestion(
              question: q['question'] as String? ?? '',
              options: (q['options'] as List? ?? []).cast<String>(),
              correctIndex: q['correct_index'] as int? ?? 0,
              explication: q['explication'] as String? ?? '',
            ))
        .toList();

    final fichesList = (json['fiches'] as List? ?? [])
        .map((f) => FicheRevision(
              titre: f['titre'] as String? ?? '',
              contenu: f['contenu'] as String? ?? '',
              pointsCles: (f['points_cles'] as List? ?? []).cast<String>(),
            ))
        .toList();

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
      resume:
          '⚠️ **Impossible d\'analyser le document** — "$title"\n\n'
          'L\'IA n\'est pas disponible pour le moment.\n\n'
          '**Raisons possibles :**\n'
          '- Quota API Gemini dépassé (limite gratuite)\n'
          '- Connexion internet indisponible\n\n'
          '**Solutions :**\n'
          '1. Attendez quelques minutes et réessayez\n'
          '2. Vérifiez votre connexion internet\n'
          '3. Utilisez le **Chat IA** pour poser vos questions directement',
      quiz: [
        QuizQuestion(
          question: 'Exemple de question sur "$title"',
          options: ['Réponse A', 'Réponse B', 'Réponse C', 'Réponse D'],
          correctIndex: 0,
          explication: 'L\'IA est temporairement indisponible.',
        ),
      ],
      fiches: [
        FicheRevision(
          titre: 'Fiche de révision',
          contenu: 'L\'IA est temporairement indisponible. Réessayez plus tard.',
          pointsCles: ['Vérifiez votre connexion internet'],
        ),
      ],
      explicationSimple: 'L\'IA est temporairement indisponible.',
      explicationDetaillee: 'L\'IA est temporairement indisponible.',
    );
  }
}
