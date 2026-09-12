import '../../config/supabase_client.dart';

class InvitationRepository {
  final _client = SupabaseConfig.client;

  /// Generate a unique invitation code for an estate (admin only)
  Future<String> generateCode({
    required String estateId,
    String role = 'tenant',
    int expiryDays = 30,
  }) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is admin of this estate
    final member = await _client
        .from('members')
        .select('id, role')
        .eq('user_id', user.id)
        .eq('estate_id', estateId)
        .single();

    if (member['role'] != 'admin' && member['role'] != 'super_admin') {
      throw Exception('Only admins can generate invitation codes');
    }

    // Generate a 6-character alphanumeric code
    final code = _generateCode();
    final expiresAt = DateTime.now().add(Duration(days: expiryDays));

    await _client.from('invitation_codes').insert({
      'estate_id': estateId,
      'code': code,
      'created_by': member['id'],
      'role': role,
      'expires_at': expiresAt.toIso8601String(),
    });

    return code;
  }

  /// Join an estate using an invitation code
  Future<String> joinWithCode(String code) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Find the invitation code
    final invitation = await _client
        .from('invitation_codes')
        .select()
        .eq('code', code)
        .eq('is_used', false)
        .maybeSingle();

    if (invitation == null) {
      throw Exception('Invalid or already used invitation code');
    }

    // Check expiry
    if (invitation['expires_at'] != null) {
      final expiresAt = DateTime.parse(invitation['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('This invitation code has expired');
      }
    }

    final estateId = invitation['estate_id'] as String;
    final role = invitation['role'] as String;

    // Check if user is already a member of this estate
    final existing = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .eq('estate_id', estateId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You are already a member of this estate');
    }

    // Create member record
    await _client.from('members').insert({
      'user_id': user.id,
      'estate_id': estateId,
      'role': role,
      'is_verified': true,
    });

    // Mark invitation as used
    final memberId = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .eq('estate_id', estateId)
        .single();

    await _client.from('invitation_codes').update({
      'is_used': true,
      'used_by': memberId['id'],
    }).eq('id', invitation['id']);

    return estateId;
  }

  /// Get active invitation codes for an estate (admin only)
  Future<List<Map<String, dynamic>>> getActiveCodes(String estateId) async {
    final data = await _client
        .from('invitation_codes')
        .select()
        .eq('estate_id', estateId)
        .eq('is_used', false)
        .order('created_at', ascending: false);

    return data;
  }

  /// Revoke an invitation code
  Future<void> revokeCode(String codeId) async {
    await _client.from('invitation_codes').delete().eq('id', codeId);
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
