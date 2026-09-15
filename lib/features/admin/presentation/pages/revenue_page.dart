import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../config/supabase_client.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key});

  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  double _totalRevenue = 0;
  double _transactionFees = 0;
  List<Map<String, dynamic>> _estateRevenue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  Future<void> _loadRevenue() async {
    setState(() => _isLoading = true);
    try {
      final paymentsFuture = SupabaseConfig.client
          .from('payments')
          .select('amount, platform_fee, estate_id, estates(name)')
          .eq('status', 'success');

      final payments = await paymentsFuture;

      double totalRevenue = 0;
      double totalFees = 0;
      final Map<String, double> estateTotals = {};
      final Map<String, String> estateNames = {};

      for (final p in payments) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final fee = (p['platform_fee'] as num?)?.toDouble() ?? 0;
        final estateId = p['estate_id'] as String? ?? '';
        totalRevenue += amount;
        totalFees += fee;
        estateTotals[estateId] = (estateTotals[estateId] ?? 0) + amount;
        final estates = p['estates'];
        if (estates != null && estates['name'] != null) {
          estateNames[estateId] = estates['name'];
        }
      }

      _estateRevenue = estateTotals.entries.map((e) => {
        'name': estateNames[e.key] ?? 'Unknown',
        'revenue': e.value,
      }).toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _transactionFees = totalFees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load revenue: $e')),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '₦${(amount / 1000).toStringAsFixed(1)}K';
    return '₦${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadRevenue,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Platform revenue breakdown',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 1;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                          children: [
                            _buildRevenueCard('Total Revenue', _formatAmount(_totalRevenue), 'All estate transactions', const Color(0xFF10B981)),
                            _buildRevenueCard('Transaction Fees', _formatAmount(_transactionFees), '1.5% platform fee', RezaColors.primaryNavy),
                            _buildRevenueCard('Active Subscriptions', '${_estateRevenue.length} estates', 'Paying subscribers', RezaColors.accentGold),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Revenue by Estate',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Estate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                                Expanded(flex: 2, child: Text('Revenue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                                Expanded(flex: 2, child: Text('Platform Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                              ],
                            ),
                          ),
                          if (_estateRevenue.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No revenue data yet', style: TextStyle(color: Color(0xFF9CA3AF)))),
                            )
                          else
                            ..._estateRevenue.map((e) {
                              final revenue = e['revenue'] as double;
                              final fee = revenue * 0.015;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(e['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatAmount(revenue), style: const TextStyle(color: Color(0xFF6B7280))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatAmount(fee), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueCard(String title, String value, String subtitle, Color color) {
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
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}
