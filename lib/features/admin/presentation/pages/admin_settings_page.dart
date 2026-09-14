import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Platform-wide configuration',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildSection('Platform', [
            _buildSettingRow('Platform Name', 'REXA', 'ResidentZ — Land Association Management'),
            _buildSettingRow('Support Email', 'support@rexa.app', 'Contact email for platform support'),
            _buildSettingRow('Default Currency', 'NGN', 'Nigerian Naira'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Payment', [
            _buildSettingRow('Payment Provider', 'Paystack', 'Integrated payment processing'),
            _buildSettingRow('Platform Fee', '1.5%', 'Percentage per transaction'),
            _buildSettingRow('Settlement Schedule', 'Daily', 'Automatic settlement to estate accounts'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Notifications', [
            _buildToggleRow('Push Notifications', 'Enable push notifications for all users', true),
            _buildToggleRow('Email Notifications', 'Send email notifications for important events', true),
            _buildToggleRow('SMS Notifications', 'Send SMS for security alerts', false),
          ]),
          const SizedBox(height: 24),
          _buildSection('Feature Flags (Global)', [
            _buildToggleRow('Community Feed', 'Allow posts, comments, and likes', true),
            _buildToggleRow('Property Listings', 'Allow property listing features', true),
            _buildToggleRow('Business Ads', 'Allow member classified ads', true),
            _buildToggleRow('IoT Integration', 'Smart gate and CCTV support', false),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2A4A),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, String description, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeThumbColor: RezaColors.primaryNavy,
          ),
        ],
      ),
    );
  }
}
