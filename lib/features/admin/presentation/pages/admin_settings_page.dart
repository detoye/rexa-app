import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../config/supabase_client.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _communityFeed = true;
  bool _propertyListings = true;
  bool _businessAds = true;
  bool _iotIntegration = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await SupabaseConfig.client
          .from('platform_settings')
          .select('key, value')
          .inFilter('key', [
        'push_notifications', 'email_notifications', 'sms_notifications',
        'community_feed', 'property_listings', 'business_ads', 'iot_integration',
      ]);

      final settings = <String, dynamic>{};
      for (final row in data) {
        settings[row['key']] = row['value'];
      }

      if (mounted) {
        setState(() {
          _pushNotifications = settings['push_notifications'] ?? true;
          _emailNotifications = settings['email_notifications'] ?? true;
          _smsNotifications = settings['sms_notifications'] ?? false;
          _communityFeed = settings['community_feed'] ?? true;
          _propertyListings = settings['property_listings'] ?? true;
          _businessAds = settings['business_ads'] ?? true;
          _iotIntegration = settings['iot_integration'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      await SupabaseConfig.client.from('platform_settings').upsert({
        'key': key,
        'value': value,
      }, onConflict: 'key');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setting updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Platform-wide configuration',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 32),
                  _buildSection('Platform', [
                    _buildInfoRow('Platform Name', 'REXA'),
                    _buildInfoRow('Support Email', 'support@rexa.app'),
                    _buildInfoRow('Default Currency', 'NGN'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Payment', [
                    _buildInfoRow('Payment Provider', 'Paystack'),
                    _buildInfoRow('Platform Fee', '1.5%'),
                    _buildInfoRow('Settlement Schedule', 'Daily'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Notifications', [
                    _buildToggleRow('Push Notifications', 'Enable push notifications for all users', _pushNotifications, (v) {
                      setState(() => _pushNotifications = v);
                      _saveSetting('push_notifications', v);
                    }),
                    _buildToggleRow('Email Notifications', 'Send email notifications for important events', _emailNotifications, (v) {
                      setState(() => _emailNotifications = v);
                      _saveSetting('email_notifications', v);
                    }),
                    _buildToggleRow('SMS Notifications', 'Send SMS for security alerts', _smsNotifications, (v) {
                      setState(() => _smsNotifications = v);
                      _saveSetting('sms_notifications', v);
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Feature Flags', [
                    _buildToggleRow('Community Feed', 'Allow posts, comments, and likes', _communityFeed, (v) {
                      setState(() => _communityFeed = v);
                      _saveSetting('community_feed', v);
                    }),
                    _buildToggleRow('Property Listings', 'Allow property listing features', _propertyListings, (v) {
                      setState(() => _propertyListings = v);
                      _saveSetting('property_listings', v);
                    }),
                    _buildToggleRow('Business Ads', 'Allow member classified ads', _businessAds, (v) {
                      setState(() => _businessAds = v);
                      _saveSetting('business_ads', v);
                    }),
                    _buildToggleRow('IoT Integration', 'Smart gate and CCTV support', _iotIntegration, (v) {
                      setState(() => _iotIntegration = v);
                      _saveSetting('iot_integration', v);
                    }),
                  ]),
                ],
              ),
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
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A))),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, String description, bool value, Function(bool) onChanged) {
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
            onChanged: onChanged,
            activeThumbColor: RezaColors.primaryNavy,
          ),
        ],
      ),
    );
  }
}
