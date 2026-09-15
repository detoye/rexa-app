import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/supabase_client.dart';
import 'config/theme.dart';
import 'reza_app.dart';
import 'features/admin/presentation/platform_admin_app.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/onboarding/presentation/role_selection_screen.dart';
import 'features/onboarding/presentation/create_estate_screen.dart';
import 'features/onboarding/presentation/join_estate_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/members/presentation/members_screen.dart';
import 'features/finances/presentation/finances_screen.dart';
import 'features/governance/presentation/governance_screen.dart';
import 'features/property/presentation/property_screen.dart';
import 'features/security/presentation/security_screen.dart';
import 'features/communications/presentation/communications_screen.dart';
import 'features/community/presentation/community_feed_screen.dart';
import 'features/business/presentation/business_ads_screen.dart';
import 'features/wallet/presentation/wallet_screen.dart';
import 'features/subscription/presentation/subscription_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/admin/presentation/manage_invitations_screen.dart';
import 'features/shell/presentation/mobile_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  if (kIsWeb) {
    runApp(const WebEntry());
  } else {
    runApp(
      const ProviderScope(child: RezaApp()),
    );
  }
}

class WebEntry extends StatefulWidget {
  const WebEntry({super.key});

  @override
  State<WebEntry> createState() => _WebEntryState();
}

class _WebEntryState extends State<WebEntry> {
  bool _isLoading = true;
  bool _isPlatformAdmin = false;
  bool _hasMember = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    SupabaseConfig.auth.onAuthStateChange.listen((_) => _checkRole());
  }

  Future<void> _checkRole() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isPlatformAdmin = false;
          _hasMember = false;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('platform_admins')
            .select('id')
            .eq('id', user.id)
            .maybeSingle(),
        SupabaseConfig.client
            .from('members')
            .select('id')
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isPlatformAdmin = results[0] != null;
          _hasMember = results[1] != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isPlatformAdmin = false;
          _hasMember = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: RezaColors.primaryNavy,
          body: const Center(
            child: CircularProgressIndicator(color: RezaColors.accentGold),
          ),
        ),
      );
    }

    // Only show PlatformAdminApp for pure platform admins (no estate membership)
    if (_isLoggedIn && _isPlatformAdmin && !_hasMember) {
      return const PlatformAdminApp();
    }

    return ProviderScope(
      child: MaterialApp.router(
        title: 'ResidentZ',
        debugShowCheckedModeBanner: false,
        theme: RezaTheme.lightTheme,
        darkTheme: RezaTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: _webRouter,
      ),
    );
  }
}

Future<String?> _webAuthRedirect(BuildContext context, GoRouterState state) async {
  final session = SupabaseConfig.auth.currentSession;
  final location = state.matchedLocation;

  final publicRoutes = ['/login', '/register', '/', '/role-selection', '/create-estate', '/join'];
  final isPublic = publicRoutes.contains(location);

  if (session == null) {
    return isPublic ? null : '/login';
  }

  if (isPublic && location != '/role-selection' && location != '/create-estate' && location != '/join') {
    return '/role-selection';
  }

  try {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return isPublic ? null : '/login';

    final results = await Future.wait([
      SupabaseConfig.client
          .from('platform_admins')
          .select('id')
          .eq('id', user.id)
          .maybeSingle(),
      SupabaseConfig.client
          .from('members')
          .select('id')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle(),
    ]);

    final isAdmin = results[0] != null;
    final hasMember = results[1] != null;

    if (!isAdmin && !hasMember && !['/role-selection', '/create-estate', '/join'].contains(location)) {
      return '/role-selection';
    }

    if (isAdmin && !hasMember && location != '/create-estate') {
      return '/create-estate';
    }

    return null;
  } catch (e) {
    return null;
  }
}

final _webRouter = GoRouter(
  initialLocation: '/',
  redirect: _webAuthRedirect,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _InitialRedirect(),
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/role-selection', builder: (_, _) => const RoleSelectionScreen()),
    GoRoute(path: '/create-estate', builder: (_, _) => const CreateEstateScreen()),
    GoRoute(path: '/join', builder: (_, _) => const JoinEstateScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MobileShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/community', builder: (_, _) => const CommunityFeedScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/security', builder: (_, _) => const SecurityScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
      ],
    ),
    GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
    GoRoute(path: '/finances', builder: (_, _) => const FinancesScreen()),
    GoRoute(path: '/governance', builder: (_, _) => const GovernanceScreen()),
    GoRoute(path: '/property', builder: (_, _) => const PropertyScreen()),
    GoRoute(path: '/communications', builder: (_, _) => const CommunicationsScreen()),
    GoRoute(path: '/business', builder: (_, _) => const BusinessAdsScreen()),
    GoRoute(path: '/subscription', builder: (_, _) => const SubscriptionScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    GoRoute(path: '/manage-invitations', builder: (_, _) => const ManageInvitationsScreen()),
  ],
);

class _InitialRedirect extends StatelessWidget {
  const _InitialRedirect();
  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.auth.currentSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(session != null ? '/dashboard' : '/login');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: RezaColors.accentGold)),
    );
  }
}
