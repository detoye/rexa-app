import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class RevenuePage extends StatelessWidget {
  const RevenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2A4A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Platform revenue breakdown',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),
            _buildRevenueCards(),
            const SizedBox(height: 32),
            _buildRevenueTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCards() {
    return LayoutBuilder(
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
            _buildRevenueCard('Total Revenue', '₦2,450,000', '+12.5% from last month', const Color(0xFF10B981)),
            _buildRevenueCard('Transaction Fees', '₦1,850,000', '1.5% on ₦123M volume', RezaColors.primaryNavy),
            _buildRevenueCard('Subscriptions', '₦600,000', '8 active subscribers', RezaColors.accentGold),
          ],
        );
      },
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
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTable() {
    return Container(
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2A4A),
              ),
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
                Expanded(flex: 2, child: Text('Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                Expanded(flex: 2, child: Text('Transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                Expanded(flex: 2, child: Text('Fees Earned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                Expanded(flex: 2, child: Text('Sub Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
              ],
            ),
          ),
          _buildRevenueRow('Lekki Gardens', 'Premium', '₦45,200,000', '₦678,000', '₦25,000'),
          _buildRevenueRow('Banana Island Estate', 'Basic', '₦32,100,000', '₦481,500', '₦8,000'),
          _buildRevenueRow('Maitama CDA', 'Free', '₦18,500,000', '₦277,500', '₦0'),
          _buildRevenueRow('Ikoyi Phase 1', 'Basic', '₦27,200,000', '₦408,000', '₦8,000'),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String estate, String plan, String transactions, String fees, String subFee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(estate, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
          ),
          Expanded(
            flex: 2,
            child: Text(plan, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(transactions, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(fees, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(subFee, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
