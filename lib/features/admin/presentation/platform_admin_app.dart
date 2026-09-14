import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import 'admin_login_screen.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/estates_page.dart';
import 'pages/plans_page.dart';
import 'pages/revenue_page.dart';
import 'pages/admin_settings_page.dart';

final adminRouter = GoRouter(
  initialLocation: '/admin',
  redirect: (context, state) {
    final user = SupabaseConfig.auth.currentUser;
    final isLoginRoute = state.matchedLocation == '/admin/login';

    if (user == null && !isLoginRoute) return '/admin/login';
    if (user != null && isLoginRoute) return '/admin';
    return null;
  },
  routes: [
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminShell(),
    ),
    GoRoute(
      path: '/admin/estates',
      builder: (context, state) => const AdminShell(child: EstatesPage()),
    ),
    GoRoute(
      path: '/admin/plans',
      builder: (context, state) => const AdminShell(child: PlansPage()),
    ),
    GoRoute(
      path: '/admin/revenue',
      builder: (context, state) => const AdminShell(child: RevenuePage()),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminShell(child: AdminSettingsPage()),
    ),
  ],
);

class AdminShell extends StatelessWidget {
  final Widget? child;
  const AdminShell({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(child: child ?? const AdminDashboardPage()),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: RezaColors.primaryNavy,
        border: Border(right: BorderSide(color: Color(0xFF2A3A5A))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: RezaColors.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('R', style: TextStyle(color: RezaColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REXA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Platform Admin', style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A3A5A), height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildNavItem(context, icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/admin', isSelected: currentPath == '/admin'),
                  _buildNavItem(context, icon: Icons.apartment_outlined, label: 'Estates', route: '/admin/estates', isSelected: currentPath == '/admin/estates'),
                  _buildNavItem(context, icon: Icons.card_membership_outlined, label: 'Subscription Plans', route: '/admin/plans', isSelected: currentPath == '/admin/plans'),
                  _buildNavItem(context, icon: Icons.analytics_outlined, label: 'Revenue', route: '/admin/revenue', isSelected: currentPath == '/admin/revenue'),
                  const Spacer(),
                  _buildNavItem(context, icon: Icons.settings_outlined, label: 'Settings', route: '/admin/settings', isSelected: currentPath == '/admin/settings'),
                  const SizedBox(height: 8),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required String route, bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? RezaColors.accentGold : const Color(0xFF8B9BB4), size: 20),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF8B9BB4), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
        selected: isSelected,
        selectedTileColor: const Color(0xFF2A3A5A).withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        dense: true,
        onTap: () => context.go(route),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
        title: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        dense: true,
        onTap: () async {
          await SupabaseConfig.auth.signOut();
          if (context.mounted) {
            context.go('/admin/login');
          }
        },
      ),
    );
  }
}

class PlatformAdminApp extends StatelessWidget {
  const PlatformAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'REXA Platform Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: RezaColors.primaryNavy,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B2A4A),
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: RezaColors.primaryNavy, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: RezaColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routerConfig: adminRouter,
    );
  }
}
