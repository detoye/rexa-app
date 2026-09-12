import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/onboarding/presentation/splash_screen.dart';
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
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/wallet/presentation/wallet_screen.dart';
import 'features/admin/presentation/manage_invitations_screen.dart';
import 'features/subscription/presentation/subscription_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinEstateScreen(),
      ),
      GoRoute(
        path: '/manage-invitations',
        builder: (context, state) => const ManageInvitationsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const MembersScreen(),
      ),
      GoRoute(
        path: '/finances',
        builder: (context, state) => const FinancesScreen(),
      ),
      GoRoute(
        path: '/governance',
        builder: (context, state) => const GovernanceScreen(),
      ),
      GoRoute(
        path: '/property',
        builder: (context, state) => const PropertyScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/communications',
        builder: (context, state) => const CommunicationsScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityFeedScreen(),
      ),
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessAdsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class RezaApp extends ConsumerWidget {
  const RezaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ResidentZ',
      debugShowCheckedModeBanner: false,
      theme: RezaTheme.lightTheme,
      darkTheme: RezaTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
