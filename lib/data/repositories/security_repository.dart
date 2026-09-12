import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class SecurityRepository {
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

  Future<List<SecurityAlert>> getActiveAlerts(String estateId) async {
    final data = await _client
        .from('security_alerts')
        .select()
        .eq('estate_id', estateId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return data.map((a) => SecurityAlert.fromJson(a)).toList();
  }

  Future<List<GuestManifest>> getGuestManifest(String estateId) async {
    final data = await _client
        .from('guest_manifest')
        .select()
        .eq('estate_id', estateId)
        .order('check_in_time', ascending: false)
        .limit(20);

    return data.map((g) => GuestManifest.fromJson(g)).toList();
  }

  Future<SecurityAlert> createAlert({
    required String estateId,
    required String title,
    required String description,
    String severity = 'medium',
  }) async {
    final data = await _client
        .from('security_alerts')
        .insert({
          'estate_id': estateId,
          'title': title,
          'description': description,
          'severity': severity,
          'is_active': true,
        })
        .select()
        .single();

    return SecurityAlert.fromJson(data);
  }

  Future<GuestManifest> checkInGuest({
    required String estateId,
    required String visitorName,
    String? visitorPhone,
    String? purpose,
    String? hostMemberId,
  }) async {
    final data = await _client
        .from('guest_manifest')
        .insert({
          'estate_id': estateId,
          'visitor_name': visitorName,
          'visitor_phone': visitorPhone,
          'purpose': purpose,
          'host_member_id': hostMemberId,
          'check_in_time': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return GuestManifest.fromJson(data);
  }

  Future<void> checkOutGuest(String guestId) async {
    await _client.from('guest_manifest').update({
      'check_out_time': DateTime.now().toIso8601String(),
    }).eq('id', guestId);
  }
}
