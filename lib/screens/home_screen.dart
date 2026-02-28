// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'filiere_screen.dart';
import 'search_screen.dart';
import 'admin/admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomePage(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Recherche',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  provider.isAdminLogged ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
                  color: provider.isAdminLogged ? AppTheme.accentGold : AppTheme.white,
                ),
                onPressed: () {
                  if (provider.isAdminLogged) {
                    _showAdminMenu(context, provider);
                  } else {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/images/ensea_logo.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GBAKI ENSEA',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'Bibliothèque académique',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Choisissez votre filière',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('3', 'Filières', Icons.school_outlined),
                  _buildDivider(),
                  _buildStat('14', 'Niveaux', Icons.layers_outlined),
                  _buildDivider(),
                  _buildStat('IA', 'Intégrée', Icons.auto_awesome_outlined),
                ],
              ),
            ),
          ),

          // Filières
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filiere = provider.filieres[index];
                  return _FiliereCard(filiere: filiere);
                },
                childCount: provider.filieres.length,
              ),
            ),
          ),

          // Espace admin
          if (provider.isAdminLogged)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFE8901A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AppTheme.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Mode Administrateur',
                              style: TextStyle(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text('Vous pouvez gérer les documents',
                              style: TextStyle(color: AppTheme.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue)),
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: AppTheme.lightGray);
  }

  void _showAdminMenu(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Menu Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Se déconnecter'),
              onTap: () {
                Navigator.pop(ctx);
                provider.logoutAdmin();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FiliereCard extends StatelessWidget {
  final Filiere filiere;
  const _FiliereCard({required this.filiere});

  Color get _cardColor {
    switch (filiere.id) {
      case 'as':
        return const Color(0xFF1B4B8A);
      case 'ise':
        return const Color(0xFF0D6E5C);
      case 'ips':
        return const Color(0xFF5B2D8A);
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FiliereScreen(filiere: filiere),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _cardColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Bande colorée gauche
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 6, color: _cardColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(filiere.icon, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filiere.nom,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _cardColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            filiere.description,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${filiere.niveaux.length} niveaux',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 18, color: _cardColor.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
