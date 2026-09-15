import '../../config/supabase_client.dart';

class VisitorCodeRepository {
  final _client = SupabaseConfig.client;

  /// Get current user's member ID
  Future<String?> _getCurrentMemberId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['id'] as String?;
  }

  /// Get current user's estate ID
  Future<String?> getCurrentEstateId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('estate_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['estate_id'] as String?;
  }

  /// Create a visitor code (tenant creates for their guest)
  Future<Map<String, dynamic>> createVisitorCode({
    required String estateId,
    required String visitorName,
    String? visitorPhone,
    String? purpose,
    int expiryHours = 24,
  }) async {
    final memberId = await _getCurrentMemberId();
    if (memberId == null) throw Exception('Not a member of this estate');

    final code = _generateCode();
    final expiresAt = DateTime.now().add(Duration(hours: expiryHours));

    final data = await _client.from('visitor_codes').insert({
      'estate_id': estateId,
      'host_member_id': memberId,
      'code': code,
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'purpose': purpose,
      'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    return data;
  }

  /// Get visitor codes created by the current user
  Future<List<Map<String, dynamic>>> getMyVisitorCodes(String estateId) async {
    final memberId = await _getCurrentMemberId();
    if (memberId == null) return [];

    final data = await _client
        .from('visitor_codes')
        .select()
        .eq('estate_id', estateId)
        .eq('host_member_id', memberId)
        .order('created_at', ascending: false)
        .limit(20);

    return data;
  }

  /// Verify a visitor code (security scans at gate)
  Future<Map<String, dynamic>> verifyVisitorCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    final visitorCode = await _client
        .from('visitor_codes')
        .select('*, members!host_member_id(user_id, users:id(full_name))')
        .eq('code', normalizedCode)
        .eq('is_used', false)
        .maybeSingle();

    if (visitorCode == null) {
      throw Exception('Invalid or already used visitor code');
    }

    // Check expiry
    final expiresAt = DateTime.parse(visitorCode['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('This visitor code has expired');
    }

    return visitorCode;
  }

  /// Mark a visitor code as used (security checks in the guest)
  Future<void> markCodeAsUsed(String codeId) async {
    await _client.from('visitor_codes').update({
      'is_used': true,
      'used_at': DateTime.now().toIso8601String(),
    }).eq('id', codeId);
  }

  /// Get all active visitor codes for the estate (security/admin view)
  Future<List<Map<String, dynamic>>> getActiveVisitorCodes(String estateId) async {
    final data = await _client
        .from('visitor_codes')
        .select()
        .eq('estate_id', estateId)
        .eq('is_used', false)
        .order('created_at', ascending: false);

    return data;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(rng + i * 7) % chars.length];
    }
    return code;
  }
}
