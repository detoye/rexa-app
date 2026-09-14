import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/announcement_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _memberRepo = MemberRepository();
  final _paymentRepo = PaymentRepository();
  final _announcementRepo = AnnouncementRepository();

  int _memberCount = 0;
  double _totalCollected = 0;
  double _outstanding = 0;
  int _announcementCount = 0;
  bool _isLoading = true;
  String? _estateId;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata;
        if (metadata != null && metadata['full_name'] != null) {
          _userName = (metadata['full_name'] as String).split(' ').first;
        }
      }

      _estateId = await _memberRepo.getCurrentEstateId();
      if (_estateId != null) {
        final results = await Future.wait([
          _memberRepo.getMemberCount(_estateId!),
          _paymentRepo.getTotalCollected(_estateId!),
          _paymentRepo.getOutstanding(_estateId!),
          _announcementRepo.getAnnouncements(_estateId!),
        ]);

        setState(() {
          _memberCount = results[0] as int;
          _totalCollected = results[1] as double;
          _outstanding = results[2] as double;
          _announcementCount = (results[3] as List).length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.gridColumns(context);
    final isWide = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ResponsiveLayout.centerContent(
                  context,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: Theme.of(context).bodyMedium,
                                ),
                                Text(
                                  _userName,
                                  style: Theme.of(context).headlineMedium,
                                ),
                              ],
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: RezaColors.accentGold,
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: RezaColors.primaryNavy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        Text('Quick Actions', style: Theme.of(context).headlineMedium),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                          children: [
                            QuickActionCard(
                              icon: Icons.people_outline,
                              label: 'Members',
                              onTap: () => context.go('/members'),
                            ),
                            QuickActionCard(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Finances',
                              onTap: () => context.go('/finances'),
                            ),
                            QuickActionCard(
                              icon: Icons.gavel_outlined,
                              label: 'Governance',
                              onTap: () => context.go('/governance'),
                            ),
                            QuickActionCard(
                              icon: Icons.home_outlined,
                              label: 'Property',
                              onTap: () => context.go('/property'),
                            ),
                            QuickActionCard(
                              icon: Icons.security_outlined,
                              label: 'Security',
                              onTap: () => context.go('/security'),
                            ),
                            QuickActionCard(
                              icon: Icons.campaign_outlined,
                              label: 'Announce',
                              onTap: () => context.go('/communications'),
                            ),
                            QuickActionCard(
                              icon: Icons.forum_outlined,
                              label: 'Community',
                              onTap: () => context.go('/community'),
                            ),
                            QuickActionCard(
                              icon: Icons.business_outlined,
                              label: 'Business',
                              onTap: () => context.go('/business'),
                            ),
                            QuickActionCard(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Wallet',
                              onTap: () => context.go('/wallet'),
                            ),
                            QuickActionCard(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Plan',
                              onTap: () => context.go('/subscription'),
                            ),
                            QuickActionCard(
                              icon: Icons.vpn_key_outlined,
                              label: 'Join',
                              onTap: () => context.go('/join'),
                            ),
                            QuickActionCard(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () => context.go('/profile'),
                            ),
                            QuickActionCard(
                              icon: Icons.more_horiz,
                              label: 'More',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overview', style: Theme.of(context).headlineMedium),
                            Text(
                              '$_announcementCount announcements',
                              style: const TextStyle(color: RezaColors.textGray, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildOverviewCard(
                                      Icons.people,
                                      'Total Members',
                                      '$_memberCount',
                                      RezaColors.accentGold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildOverviewCard(
                                      Icons.trending_up,
                                      'Total Collected',
                                      '₦${_formatAmount(_totalCollected)}',
                                      RezaColors.successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildOverviewCard(
                                      Icons.trending_down,
                                      'Outstanding',
                                      '₦${_formatAmount(_outstanding)}',
                                      RezaColors.errorRed,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildOverviewCard(
                                    Icons.people,
                                    'Total Members',
                                    '$_memberCount',
                                    RezaColors.accentGold,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOverviewCard(
                                    Icons.trending_up,
                                    'Total Collected',
                                    '₦${_formatAmount(_totalCollected)}',
                                    RezaColors.successGreen,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOverviewCard(
                                    Icons.trending_down,
                                    'Outstanding',
                                    '₦${_formatAmount(_outstanding)}',
                                    RezaColors.errorRed,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RezaColors.primaryNavy, Color(0xFF2A3A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Dues Collected',
                style: TextStyle(color: RezaColors.textGray),
              ),
              const SizedBox(height: 4),
              Text(
                '₦${_formatAmount(_totalCollected)}',
                style: Theme.of(context).headlineMedium?.copyWith(
                  color: RezaColors.accentGold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RezaColors.successGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(color: RezaColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: RezaColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: RezaColors.textGray, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
