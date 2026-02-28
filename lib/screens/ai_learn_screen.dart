// lib/screens/ai_learn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/gemini_service.dart';

class AILearnScreen extends StatefulWidget {
  final Document document;
  const AILearnScreen({super.key, required this.document});

  @override
  State<AILearnScreen> createState() => _AILearnScreenState();
}

class _AILearnScreenState extends State<AILearnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GeminiService _gemini = GeminiService();

  AIContent? _aiContent;
  bool _isLoading = true;
  String? _error;

  // Quiz state
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  int _score = 0;
  bool _quizFinished = false;

  // Chat
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;

  final List<String> _tabs = ['Résumé', 'Quiz', 'Fiches', 'Expliquer', 'Demander'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAIContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadAIContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final content = await _gemini.analyzeDocument(
        documentTitle: widget.document.titre,
        documentType: widget.document.typeLabel,
      );
      if (mounted) {
        setState(() {
          _aiContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement. Vérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A2580),
        foregroundColor: AppTheme.white,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.document.titre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 3,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResumeTab(),
                    _buildQuizTab(),
                    _buildFichesTab(),
                    _buildExplainTab(),
                    _buildChatTab(),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4A2580).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF4A2580),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'L\'IA analyse votre document...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Génération du résumé, quiz et fiches de révision',
            style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppTheme.textMedium)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAIContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2580)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RÉSUMÉ ────────────────────────────────────────────────
  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Résumé du document', Icons.summarize_outlined,
              const Color(0xFF1B4B8A)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: MarkdownBody(
              data: _aiContent!.resume,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.7),
                h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUIZ ───────────────────────────────────────────────────
  Widget _buildQuizTab() {
    if (_aiContent!.quiz.isEmpty) {
      return const Center(child: Text('Aucun quiz disponible'));
    }

    if (_quizFinished) {
      return _buildQuizResult();
    }

    final question = _aiContent!.quiz[_currentQuestion];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question ${_currentQuestion + 1}/${_aiContent!.quiz.length}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text('Score: $_score/${_aiContent!.quiz.length}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / _aiContent!.quiz.length,
            backgroundColor: AppTheme.lightGray,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4A2580)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A2580), Color(0xFF6C3FA5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(question.options.length, (index) {
            Color bgColor = AppTheme.white;
            Color borderColor = AppTheme.lightGray;
            Color textColor = AppTheme.textDark;

            if (_showResult) {
              if (index == question.correctIndex) {
                bgColor = AppTheme.success.withValues(alpha: 0.1);
                borderColor = AppTheme.success;
                textColor = AppTheme.success;
              } else if (index == _selectedAnswer) {
                bgColor = AppTheme.error.withValues(alpha: 0.1);
                borderColor = AppTheme.error;
                textColor = AppTheme.error;
              }
            } else if (index == _selectedAnswer) {
              bgColor = AppTheme.primaryBlue.withValues(alpha: 0.1);
              borderColor = AppTheme.primaryBlue;
              textColor = AppTheme.primaryBlue;
            }

            return GestureDetector(
              onTap: _showResult ? null : () {
                setState(() => _selectedAnswer = index);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          ['A', 'B', 'C', 'D'][index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: borderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                      ),
                    ),
                    if (_showResult && index == question.correctIndex)
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    if (_showResult && index == _selectedAnswer && index != question.correctIndex)
                      const Icon(Icons.cancel, color: AppTheme.error, size: 20),
                  ],
                ),
              ),
            );
          }),

          // Explication
          if (_showResult) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explication,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Bouton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAnswer == null ? null : _handleQuizAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2580),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _showResult
                    ? (_currentQuestion < _aiContent!.quiz.length - 1
                        ? 'Question suivante →'
                        : 'Voir résultat')
                    : 'Valider',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuizAction() {
    if (!_showResult) {
      final isCorrect = _selectedAnswer == _aiContent!.quiz[_currentQuestion].correctIndex;
      setState(() {
        _showResult = true;
        if (isCorrect) _score++;
      });
    } else {
      if (_currentQuestion < _aiContent!.quiz.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedAnswer = null;
          _showResult = false;
        });
      } else {
        setState(() => _quizFinished = true);
      }
    }
  }

  Widget _buildQuizResult() {
    final pct = (_score / _aiContent!.quiz.length * 100).round();
    Color color = pct >= 80 ? AppTheme.success : pct >= 50 ? AppTheme.accentGold : AppTheme.error;
    String message = pct >= 80 ? 'Excellent ! 🎉' : pct >= 50 ? 'Bien ! Continuez ! 💪' : 'À retravailler 📚';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 4),
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$_score/${_aiContent!.quiz.length} bonnes réponses',
              style: const TextStyle(fontSize: 16, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentQuestion = 0;
                  _selectedAnswer = null;
                  _showResult = false;
                  _score = 0;
                  _quizFinished = false;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recommencer'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2580)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FICHES ────────────────────────────────────────────────
  Widget _buildFichesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _aiContent!.fiches.length,
      itemBuilder: (context, index) {
        final fiche = _aiContent!.fiches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6E5C).withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6E5C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fiche.titre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fiche.contenu,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMedium, height: 1.6),
                    ),
                    if (fiche.pointsCles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Points clés :',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 8),
                      ...fiche.pointsCles.map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFF0D6E5C), fontWeight: FontWeight.bold, fontSize: 14)),
                                Expanded(
                                  child: Text(point,
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── EXPLIQUER ─────────────────────────────────────────────
  Widget _buildExplainTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.white,
            child: TabBar(
              labelColor: const Color(0xFF4A2580),
              unselectedLabelColor: AppTheme.textLight,
              indicatorColor: const Color(0xFF4A2580),
              tabs: const [
                Tab(text: 'Simple'),
                Tab(text: 'Détaillée'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ExplainCard(
                  content: _aiContent!.explicationSimple,
                  label: 'Explication simplifiée',
                  color: AppTheme.primaryBlue,
                  icon: Icons.lightbulb_outline,
                ),
                _ExplainCard(
                  content: _aiContent!.explicationDetaillee,
                  label: 'Explication détaillée',
                  color: const Color(0xFF4A2580),
                  icon: Icons.school_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHAT ───────────────────────────────────────────────────
  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A2580).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.chat_outlined,
                            size: 48, color: Color(0xFF4A2580)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Posez une question sur ce document',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('L\'IA vous répondra immédiatement',
                          style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return _ChatBubble(message: msg['content']!, isUser: isUser);
                  },
                ),
        ),
        if (_isChatLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A2580)),
                ),
                SizedBox(width: 8),
                Text('L\'IA réfléchit...', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppTheme.lightGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppTheme.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF4A2580), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.offWhite,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A2580), Color(0xFF6C3FA5)],
                    ),
                  ),
                  child: const Icon(Icons.send, color: AppTheme.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isChatLoading) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isChatLoading = true;
    });

    final answer = await GeminiService().askQuestion(
      question: text,
      documentTitle: widget.document.titre,
    );

    if (mounted) {
      setState(() {
        _chatMessages.add({'role': 'ai', 'content': answer});
        _isChatLoading = false;
      });
    }
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }
}

class _ExplainCard extends StatelessWidget {
  final String content;
  final String label;
  final Color color;
  final IconData icon;
  const _ExplainCard({
    required this.content,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.7),
                h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4A2580), Color(0xFF6C3FA5)],
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4A2580) : AppTheme.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message,
                      style: const TextStyle(color: AppTheme.white, fontSize: 14, height: 1.5),
                    )
                  : MarkdownBody(
                      data: message,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
