import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = SupabaseConfig.auth.currentSession;

    if (session == null) {
      context.go('/login');
      return;
    }

    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

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

      if (!mounted) return;

      final isAdmin = results[0] != null;
      final hasMember = results[1] != null;

      if (!isAdmin && !hasMember) {
        context.go('/role-selection');
      } else if (isAdmin && !hasMember) {
        context.go('/create-estate');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Rexa logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              'ResidentZ',
              style: Theme.of(context).headlineLarge?.copyWith(
                color: RezaColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nigeria\'s Premier Estate Standard',
              style: Theme.of(context).bodyMedium?.copyWith(
                color: RezaColors.textGray,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: RezaColors.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
