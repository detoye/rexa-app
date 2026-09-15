import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/role_helper.dart';
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
  bool _isAdmin = false;
  bool _hasEstate = false;
  double _myBalance = 0;
  int _myUnpaidInvoices = 0;

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

      _isAdmin = await RoleHelper.isAdmin();

      _estateId = await _memberRepo.getCurrentEstateId();
      _hasEstate = _estateId != null;
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

        // Load tenant-specific data
        if (!_isAdmin && _estateId != null) {
          final tenantUser = SupabaseConfig.auth.currentUser;
          if (tenantUser != null) {
            // Get user's member ID
            final memberData = await SupabaseConfig.client
                .from('members')
                .select('id')
                .eq('user_id', tenantUser.id)
                .eq('estate_id', _estateId!)
                .limit(1)
                .maybeSingle();

            if (memberData != null) {
              // Get unpaid invoices for this member
              final invoices = await SupabaseConfig.client
                  .from('invoices')
                  .select('amount')
                  .eq('member_id', memberData['id'])
                  .eq('is_paid', false);

              setState(() {
                _myUnpaidInvoices = invoices.length;
                _myBalance = invoices.fold<double>(
                    0, (sum, i) => sum + (i['amount'] as num).toDouble());
              });
            }
          }
        }
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
                            // === EVERYONE SEES ===
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
                              icon: Icons.security_outlined,
                              label: 'Security',
                              onTap: () => context.go('/security'),
                            ),
                            QuickActionCard(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () => context.go('/profile'),
                            ),

                            // === ADMIN ONLY ===
                            if (_isAdmin) ...[
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
                                icon: Icons.campaign_outlined,
                                label: 'Announce',
                                onTap: () => context.go('/communications'),
                              ),
                              QuickActionCard(
                                icon: Icons.workspace_premium_outlined,
                                label: 'Plan',
                                onTap: () => context.go('/subscription'),
                              ),
                              QuickActionCard(
                                icon: Icons.mail_outline,
                                label: 'Invite',
                                onTap: () => context.go('/manage-invitations'),
                              ),
                            ],

                            // === JOIN (only if not yet a member) ===
                            if (!_hasEstate)
                              QuickActionCard(
                                icon: Icons.vpn_key_outlined,
                                label: 'Join',
                                onTap: () => context.go('/join'),
                              ),
                          ],
                        ),

                        // Tenant announcements preview
                        if (!_isAdmin) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent Announcements', style: Theme.of(context).headlineMedium),
                              TextButton(
                                onPressed: () => context.go('/communications'),
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_announcementCount == 0)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: RezaColors.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('No announcements yet', style: TextStyle(color: RezaColors.textGray)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: RezaColors.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.campaign_outlined, color: RezaColors.accentGold, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$_announcementCount new announcement${_announcementCount == 1 ? '' : 's'}',
                                      style: const TextStyle(color: RezaColors.textWhite),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: RezaColors.textGray),
                                ],
                              ),
                            ),
                        ],

                        if (_isAdmin) ...[
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
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isAdmin) {
      // Admin sees estate-wide collection stats
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
                const Text('Total Dues Collected', style: TextStyle(color: RezaColors.textGray)),
                const SizedBox(height: 4),
                Text(
                  '₦${_formatAmount(_totalCollected)}',
                  style: Theme.of(context).headlineMedium?.copyWith(color: RezaColors.accentGold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RezaColors.successGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active', style: TextStyle(color: RezaColors.successGreen)),
            ),
          ],
        ),
      );
    } else {
      // Tenant sees their personal balance
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Balance', style: TextStyle(color: RezaColors.textGray)),
                if (_myUnpaidInvoices > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RezaColors.errorRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_myUnpaidInvoices unpaid',
                      style: const TextStyle(color: RezaColors.errorRed, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _myBalance > 0 ? '₦${_formatAmount(_myBalance)}' : 'All clear!',
              style: Theme.of(context).headlineMedium?.copyWith(
                color: _myBalance > 0 ? RezaColors.errorRed : RezaColors.successGreen,
              ),
            ),
            if (_myBalance > 0) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/wallet'),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RezaColors.accentGold,
                    foregroundColor: RezaColors.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
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
