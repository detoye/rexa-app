import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/subscription_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subRepo = SubscriptionRepository();
  List<SubscriptionPlan> _plans = [];
  EstateSubscription? _currentSub;
  SubscriptionPlan? _currentPlan;
  bool _isLoading = true;
  String? _estateId;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);
    try {
      _estateId = await _subRepo.getCurrentEstateId();
      if (_estateId != null) {
        final results = await Future.wait([
          _subRepo.getActivePlans(),
          _subRepo.getEstateSubscription(_estateId!),
        ]);
        _plans = results[0] as List<SubscriptionPlan>;
        _currentSub = results[1] as EstateSubscription?;

        if (_currentSub != null) {
          _currentPlan = await _subRepo.getPlanById(_currentSub!.planId);
        }

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscription: $e')),
        );
      }
    }
  }

  String _formatPrice(double price) {
    return '₦${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Subscription'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadSubscriptionData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 24),
                    Text('Available Plans', style: Theme.of(context).headlineMedium),
                    const SizedBox(height: 12),
                    ..._plans.map((plan) => _buildPlanCard(plan)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final isOnPlan = _currentSub != null && _currentPlan != null;
    final daysLeft = _currentSub?.endDate != null
        ? _currentSub!.endDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnPlan
              ? [RezaColors.primaryNavy, const Color(0xFF2A3A5A)]
              : [RezaColors.cardDark, RezaColors.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isOnPlan
            ? null
            : Border.all(color: RezaColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOnPlan ? Icons.workspace_premium : Icons.card_membership,
                color: RezaColors.accentGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isOnPlan ? _currentPlan!.name : 'Free Plan',
                style: const TextStyle(color: RezaColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOnPlan) ...[
            Text(
              '${_formatPrice(_currentPlan!.priceMonthly)}/month',
              style: const TextStyle(color: RezaColors.accentGold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Expires in $daysLeft days',
              style: TextStyle(color: daysLeft < 7 ? RezaColors.errorRed : RezaColors.textGray),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentPlan!.features.entries
                  .where((e) => e.value == true)
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RezaColors.successGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(e.key.replaceAll('_', ' '), style: const TextStyle(color: RezaColors.successGreen, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ] else ...[
            Text(
              'Upgrade to unlock all features',
              style: TextStyle(color: RezaColors.textGray, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Members: unlimited on free plan',
              style: TextStyle(color: RezaColors.textGray, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _currentPlan?.id == plan.id;
    final isUpgrade = _currentPlan == null ||
        plan.priceMonthly > (_currentPlan!.priceMonthly);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPlan
            ? Border.all(color: RezaColors.accentGold, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.bold, fontSize: 18)),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RezaColors.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Current', style: TextStyle(color: RezaColors.accentGold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${_formatPrice(plan.priceMonthly)}/mo', style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 12),
              Text('${_formatPrice(plan.priceYearly)}/yr', style: const TextStyle(color: RezaColors.textGray, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLimitChip(Icons.home, '${plan.maxEstates} estate${plan.maxEstates > 1 ? 's' : ''}'),
              const SizedBox(width: 12),
              _buildLimitChip(Icons.people, '${plan.maxMembers} members'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.features.entries
                .where((e) => e.value == true)
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RezaColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.key.replaceAll('_', ' '), style: const TextStyle(color: RezaColors.successGreen, fontSize: 11)),
                    ))
                .toList(),
          ),
          if (!isCurrentPlan) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSubscribeDialog(plan, isUpgrade),
                child: Text(isUpgrade ? 'Upgrade to ${plan.name}' : 'Downgrade to ${plan.name}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RezaColors.borderDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: RezaColors.textGray, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: RezaColors.textWhite, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSubscribeDialog(SubscriptionPlan plan, bool isUpgrade) {
    String billingCycle = 'monthly';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: RezaColors.cardDark,
              title: Text('${isUpgrade ? 'Upgrade' : 'Downgrade'} to ${plan.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select billing cycle:'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => billingCycle = 'monthly'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: billingCycle == 'monthly'
                                  ? RezaColors.accentGold.withValues(alpha: 0.2)
                                  : RezaColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                              border: billingCycle == 'monthly'
                                  ? Border.all(color: RezaColors.accentGold)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                const Text('Monthly', style: TextStyle(color: RezaColors.textWhite)),
                                Text(_formatPrice(plan.priceMonthly), style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => billingCycle = 'yearly'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: billingCycle == 'yearly'
                                  ? RezaColors.accentGold.withValues(alpha: 0.2)
                                  : RezaColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                              border: billingCycle == 'yearly'
                                  ? Border.all(color: RezaColors.accentGold)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                const Text('Yearly', style: TextStyle(color: RezaColors.textWhite)),
                                Text(_formatPrice(plan.priceYearly), style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold)),
                                Text('Save 17%', style: TextStyle(color: RezaColors.successGreen, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_estateId == null) return;
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _subRepo.subscribe(
                        estateId: _estateId!,
                        planId: plan.id,
                        billingCycle: billingCycle,
                      );
                      navigator.pop();
                      _loadSubscriptionData();
                      messenger.showSnackBar(
                        SnackBar(content: Text('Switched to ${plan.name}')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
