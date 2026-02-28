// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'document_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recherche',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trouvez vos cours, devoirs et TD',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkBlue.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Ex: probabilités, devoir statistiques...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.textLight),
                                onPressed: () {
                                  _controller.clear();
                                  provider.search('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        provider.search(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Suggestions chips
            if (_controller.text.isEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SuggestionChip(
                      label: '📊 Statistiques',
                      onTap: () => _search(provider, 'statistiques'),
                    ),
                    _SuggestionChip(
                      label: '🧮 Probabilités',
                      onTap: () => _search(provider, 'probabilités'),
                    ),
                    _SuggestionChip(
                      label: '💻 Python',
                      onTap: () => _search(provider, 'Python'),
                    ),
                    _SuggestionChip(
                      label: '📈 Économétrie',
                      onTap: () => _search(provider, 'économétrie'),
                    ),
                    _SuggestionChip(
                      label: '📝 Devoirs',
                      onTap: () => _search(provider, 'devoirs'),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _controller.text.isEmpty
                  ? _buildEmptySearch()
                  : provider.isSearching
                      ? _buildSearching()
                      : _buildResults(provider),
            ),
          ],
        ),
      ),
    );
  }

  void _search(AppProvider provider, String query) {
    _controller.text = query;
    provider.search(query);
    setState(() {});
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, size: 52, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recherchez un document',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tapez des mots-clés : matière, type,\nnuméro de devoir...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSearching() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlue),
          SizedBox(height: 16),
          Text('Recherche en cours...', style: TextStyle(color: AppTheme.textMedium)),
        ],
      ),
    );
  }

  Widget _buildResults(AppProvider provider) {
    final results = provider.searchResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: AppTheme.textLight),
            const SizedBox(height: 12),
            const Text('Aucun résultat trouvé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'autres mots-clés',
              style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${results.length} résultat(s) trouvé(s)',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _SearchResultCard(document: results[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Document document;
  const _SearchResultCard({required this.document});

  IconData get _icon {
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isWord) return Icons.description;
    if (document.isExcel) return Icons.table_chart;
    if (document.isPowerPoint) return Icons.slideshow;
    if (document.isPython) return Icons.code;
    return Icons.insert_drive_file;
  }

  Color get _iconColor {
    if (document.isPdf) return const Color(0xFFE74C3C);
    if (document.isWord) return const Color(0xFF2B5DBB);
    if (document.isPython) return const Color(0xFF3776AB);
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentScreen(document: document)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.titre,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${document.matiereName} • ${document.typeLabel}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
