import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../../../config/supabase_client.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, String> _featureLabels = {
    'announcements': 'Announcements',
    'community_feed': 'Community Feed',
    'guest_manifest': 'Guest Manifest',
    'members_view': 'Members View',
    'dues_manual': 'Manual Dues Tracking',
    'payment_gateway': 'Payment Gateway',
    'invoices': 'Invoices',
    'wallet': 'Wallet',
    'property_listings': 'Property Listings',
    'business_ads': 'Business Ads',
    'quick_deals': 'Quick Deals',
    'committees': 'Committees',
    'projects': 'Projects',
    'multi_estate': 'Multi-Estate',
    'reports_basic': 'Basic Reports',
    'reports_advanced': 'Advanced Reports',
    'api_access': 'API Access',
    'white_label': 'White Label',
    'dedicated_support': 'Dedicated Support',
    'subscription_management': 'Subscription Management',
  };

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('subscription_plans')
          .select()
          .order('display_order');
      setState(() {
        _plans = data.map((p) => {
          ...p,
          'features': Map<String, dynamic>.from(p['features'] ?? {}),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load plans: $e')),
        );
      }
    }
  }

  Future<void> _savePlan(Map<String, dynamic> plan) async {
    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.client
          .from('subscription_plans')
          .update({
            'price_monthly': plan['price_monthly'],
            'price_yearly': plan['price_yearly'],
            'max_estates': plan['max_estates'],
            'max_members': plan['max_members'],
            'features': plan['features'],
            'is_active': plan['is_active'],
          })
          .eq('id', plan['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plan['name']} plan updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                          'Subscription Plans',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure pricing, limits, and features for each plan',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                ..._plans.map((plan) => _buildPlanCard(plan)),
              ],
            ),
          );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPlanColor(plan['slug']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan['name'],
                    style: TextStyle(color: _getPlanColor(plan['slug']), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                if (plan['slug'] == 'free')
                  const Text('Default plan for new estates', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                if (plan['slug'] == 'enterprise')
                  const Text('Custom pricing — contact sales', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                const Spacer(),
                Switch(
                  value: plan['is_active'] ?? true,
                  onChanged: (val) => setState(() => plan['is_active'] = val),
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildPricingSection(plan)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildLimitsSection(plan)),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildFeaturesSection(plan)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildPricingSection(plan),
                    const SizedBox(height: 16),
                    _buildLimitsSection(plan),
                    const SizedBox(height: 16),
                    _buildFeaturesSection(plan),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _loadPlans,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _savePlan(plan),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection(Map<String, dynamic> plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pricing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 12),
        if (plan['slug'] != 'enterprise') ...[
          _buildEditableField('Monthly (₦)', plan['price_monthly'].toString(), (v) {
            plan['price_monthly'] = double.tryParse(v) ?? 0;
          }),
          const SizedBox(height: 8),
          _buildEditableField('Yearly (₦)', plan['price_yearly'].toString(), (v) {
            plan['price_yearly'] = double.tryParse(v) ?? 0;
          }),
        ] else ...[
          const Text('Custom pricing', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildLimitsSection(Map<String, dynamic> plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Limits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 12),
        _buildEditableField('Max Estates', plan['max_estates'].toString(), (v) {
          plan['max_estates'] = int.tryParse(v) ?? 1;
        }),
        const SizedBox(height: 8),
        _buildEditableField(
          'Max Members',
          plan['max_members'] == 999999 ? '999999' : plan['max_members'].toString(),
          (v) {
            plan['max_members'] = int.tryParse(v) ?? 10;
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(Map<String, dynamic> plan) {
    final features = Map<String, dynamic>.from(plan['features'] ?? {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Features', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _featureLabels.entries.map((entry) {
            final isEnabled = features[entry.key] ?? false;
            return FilterChip(
              label: Text(
                entry.value,
                style: TextStyle(fontSize: 12, color: isEnabled ? RezaColors.primaryNavy : const Color(0xFF9CA3AF)),
              ),
              selected: isEnabled,
              onSelected: (selected) {
                setState(() {
                  features[entry.key] = selected;
                  plan['features'] = features;
                });
              },
              selectedColor: RezaColors.primaryNavy.withValues(alpha: 0.1),
              checkmarkColor: RezaColors.primaryNavy,
              side: BorderSide(
                color: isEnabled ? RezaColors.primaryNavy.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          style: const TextStyle(fontSize: 14),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(String slug) {
    switch (slug) {
      case 'free': return const Color(0xFF6B7280);
      case 'basic': return const Color(0xFF3B82F6);
      case 'premium': return RezaColors.accentGold;
      case 'enterprise': return RezaColors.primaryNavy;
      default: return const Color(0xFF6B7280);
    }
  }
}
