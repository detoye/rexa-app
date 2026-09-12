import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class SubscriptionRepository {
  final _client = SupabaseConfig.client;

  Future<String?> getCurrentEstateId() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('estate_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['estate_id'] as String?;
  }

  Future<List<SubscriptionPlan>> getActivePlans() async {
    final data = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return data.map((p) => SubscriptionPlan.fromJson(p)).toList();
  }

  Future<SubscriptionPlan?> getPlanById(String planId) async {
    final data = await _client
        .from('subscription_plans')
        .select()
        .eq('id', planId)
        .maybeSingle();

    return data != null ? SubscriptionPlan.fromJson(data) : null;
  }

  Future<EstateSubscription?> getEstateSubscription(String estateId) async {
    final data = await _client
        .from('estate_subscriptions')
        .select()
        .eq('estate_id', estateId)
        .eq('is_active', true)
        .maybeSingle();

    return data != null ? EstateSubscription.fromJson(data) : null;
  }

  Future<SubscriptionPlan?> getCurrentPlan(String estateId) async {
    final sub = await getEstateSubscription(estateId);
    if (sub == null) return null;
    return getPlanById(sub.planId);
  }

  /// Subscribe estate to a plan
  Future<EstateSubscription> subscribe({
    required String estateId,
    required String planId,
    String billingCycle = 'monthly',
  }) async {
    final now = DateTime.now();
    final endDate = billingCycle == 'yearly'
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    // Deactivate any existing subscription
    await _client
        .from('estate_subscriptions')
        .update({'is_active': false})
        .eq('estate_id', estateId)
        .eq('is_active', true);

    final data = await _client
        .from('estate_subscriptions')
        .insert({
          'estate_id': estateId,
          'plan_id': planId,
          'billing_cycle': billingCycle,
          'start_date': now.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    return EstateSubscription.fromJson(data);
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String estateId) async {
    await _client
        .from('estate_subscriptions')
        .update({'is_active': false})
        .eq('estate_id', estateId)
        .eq('is_active', true);
  }

  /// Check if estate has a specific feature enabled
  Future<bool> hasFeature(String estateId, String featureKey) async {
    final plan = await getCurrentPlan(estateId);
    if (plan == null) return false;
    return plan.features[featureKey] == true;
  }

  /// Get member count for estate (to check against plan limits)
  Future<int> getEstateMemberCount(String estateId) async {
    final data = await _client
        .from('members')
        .select('id')
        .eq('estate_id', estateId);
    return data.length;
  }

  /// Check if estate can add more members
  Future<bool> canAddMember(String estateId) async {
    final plan = await getCurrentPlan(estateId);
    if (plan == null) return true; // No plan = free tier
    final memberCount = await getEstateMemberCount(estateId);
    return memberCount < plan.maxMembers;
  }
}
