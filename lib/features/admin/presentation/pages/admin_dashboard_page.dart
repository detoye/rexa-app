import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/supabase_client.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _totalEstates = 0;
  int _activeSubscriptions = 0;
  int _totalMembers = 0;
  double _platformRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        SupabaseConfig.client.from('estates').select('id'),
        SupabaseConfig.client.from('estate_subscriptions').select('id').eq('is_active', true),
        SupabaseConfig.client.from('members').select('id'),
        SupabaseConfig.client.from('payments').select('platform_fee').eq('status', 'success'),
      ]);

      final estates = results[0] as List;
      final subs = results[1] as List;
      final members = results[2] as List;
      final payments = results[3] as List;

      double totalFees = 0;
      for (final p in payments) {
        totalFees += (p['platform_fee'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalEstates = estates.length;
          _activeSubscriptions = subs.length;
          _totalMembers = members.length;
          _platformRevenue = totalFees;
        });
      }
    } catch (e) {
      // Stats failed to load, keep defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
          const SizedBox(height: 8),
          const Text('Overview of your platform', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          _buildStatCards(),
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard('Total Estates', _totalEstates.toString(), Icons.apartment, const Color(0xFF3B82F6)),
            _buildStatCard('Active Subscriptions', _activeSubscriptions.toString(), Icons.card_membership, const Color(0xFF10B981)),
            _buildStatCard('Total Members', _totalMembers.toString(), Icons.people, const Color(0xFFF59E0B)),
            _buildStatCard('Platform Revenue', '₦${_formatRevenue(_platformRevenue)}', Icons.trending_up, RezaColors.primaryNavy),
          ],
        );
      },
    );
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('Manage Estates', Icons.apartment, () => context.go('/admin/estates')),
              _buildActionButton('Edit Plans', Icons.card_membership, () => context.go('/admin/plans')),
              _buildActionButton('View Revenue', Icons.analytics, () => context.go('/admin/revenue')),
              _buildActionButton('Platform Settings', Icons.settings, () => context.go('/admin/settings')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF374151)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
