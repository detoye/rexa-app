import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class EstatesPage extends StatelessWidget {
  const EstatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estates',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2A4A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage all registered estates on the platform',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Estate'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildEstatesTable(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search estates...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Estate Name', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Location', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Members', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Plan', style: _headerStyle)),
                Expanded(flex: 1, child: Text('Status', style: _headerStyle)),
                SizedBox(width: 48),
              ],
            ),
          ),
          _buildTableRow('Lekki Gardens', 'Lekki, Lagos', '142', 'Premium', true),
          _buildTableRow('Banana Island Estate', 'Ikoyi, Lagos', '89', 'Basic', true),
          _buildTableRow('Maitama CDA', 'Maitama, Abuja', '56', 'Free', true),
          _buildTableRow('Ikoyi Phase 1', 'Ikoyi, Lagos', '0', 'Free', false),
        ],
      ),
    );
  }

  Widget _buildTableRow(String name, String location, String members, String plan, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B2A4A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(location, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(members, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPlanColor(plan).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                plan,
                style: TextStyle(
                  color: _getPlanColor(plan),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'Free': return const Color(0xFF6B7280);
      case 'Basic': return const Color(0xFF3B82F6);
      case 'Premium': return RezaColors.accentGold;
      default: return const Color(0xFF6B7280);
    }
  }
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFF9CA3AF),
  textBaseline: TextBaseline.alphabetic,
);
