import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 500 : 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Rexa logo.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'How would you like to begin?',
                    style: TextStyle(
                      color: RezaColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the option that best describes you',
                    style: TextStyle(color: RezaColors.textGray, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _OptionCard(
                    icon: Icons.apartment_outlined,
                    title: 'Set up my estate',
                    subtitle: 'Create a new estate and become the admin',
                    onTap: () => context.go('/create-estate'),
                  ),
                  const SizedBox(height: 16),
                  _OptionCard(
                    icon: Icons.vpn_key_outlined,
                    title: 'Join an estate',
                    subtitle: 'Enter an invitation code from your admin',
                    onTap: () => context.go('/join'),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: RezaColors.textGray),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: RezaColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: RezaColors.accentGold.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RezaColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: RezaColors.accentGold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: RezaColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RezaColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: RezaColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}
