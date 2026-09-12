import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/member_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _memberRepo = MemberRepository();
  String _role = '';
  String _estateName = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final role = await RoleHelper.getCurrentUserRole();
      final estateId = await _memberRepo.getCurrentEstateId();

      String estateName = '';
      if (estateId != null) {
        final estate = await SupabaseConfig.client
            .from('estates')
            .select('name')
            .eq('id', estateId)
            .maybeSingle();
        estateName = estate?['name'] ?? '';
      }

      if (mounted) {
        setState(() {
          _role = role ?? 'member';
          _isAdmin = role == 'admin' || role == 'super_admin';
          _estateName = estateName;
        });
      }
    } catch (e) {
      // Keep defaults
    }
  }

  String _getDisplayName() {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return 'Guest';
    final metadata = user.userMetadata;
    if (metadata != null && metadata['full_name'] != null) {
      return metadata['full_name'] as String;
    }
    return user.email ?? 'Guest';
  }

  String _getEmail() {
    final user = SupabaseConfig.auth.currentUser;
    return user?.email ?? '';
  }

  String _getInitials() {
    final name = _getDisplayName();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: RezaColors.accentGold,
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: RezaColors.primaryNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getDisplayName(),
              style: const TextStyle(
                color: RezaColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(_getEmail(), style: Theme.of(context).bodyMedium),
            if (_estateName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RezaColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_estateName • ${_role.toUpperCase()}',
                  style: const TextStyle(color: RezaColors.accentGold, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSection(
              'Account',
              [
                _buildMenuItem(context, Icons.person_outline, 'Personal Information', () {}),
                if (_isAdmin)
                  _buildMenuItem(context, Icons.vpn_key_outlined, 'Manage Invitations', () {
                    context.push('/manage-invitations');
                  }),
                _buildMenuItem(context, Icons.account_balance_wallet_outlined, 'Wallet', () {
                  context.go('/wallet');
                }),
                _buildMenuItem(context, Icons.payment, 'Payment History', () {}),
                _buildMenuItem(context, Icons.workspace_premium_outlined, 'Subscription', () {
                  context.go('/subscription');
                }),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Preferences',
              [
                _buildMenuItem(context, Icons.notifications_outlined, 'Notifications', () {
                  context.go('/notifications');
                }),
                _buildMenuItem(context, Icons.settings_outlined, 'Settings', () {}),
                _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await SupabaseConfig.auth.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RezaColors.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sign Out', style: TextStyle(color: RezaColors.errorRed)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RezaColors.textGray, letterSpacing: 0.5),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: RezaColors.accentGold, size: 22),
      title: Text(title, style: const TextStyle(color: RezaColors.textWhite, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: RezaColors.textGray, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
