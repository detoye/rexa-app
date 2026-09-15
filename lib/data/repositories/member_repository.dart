import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class MemberRepository {
  final _client = SupabaseConfig.client;

  Future<String?> getCurrentEstateId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final member = await _client
        .from('members')
        .select('estate_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return member?['estate_id'] as String?;
  }

  Future<Member?> getCurrentMember() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('members')
        .select()
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Member.fromJson(data);
  }

  Future<List<Member>> getMembersByEstate(String estateId) async {
    final data = await _client
        .from('members')
        .select('*, users!user_id(full_name)')
        .eq('estate_id', estateId)
        .order('created_at', ascending: false);

    return data.map((m) => Member.fromJson(m)).toList();
  }

  Future<List<Member>> searchMembers(String estateId, String query) async {
    final data = await _client
        .from('members')
        .select('*, users!user_id(full_name)')
        .eq('estate_id', estateId)
        .or('role.ilike.%$query%,house_number.ilike.%$query%,street.ilike.%$query%,users.full_name.ilike.%$query%')
        .order('created_at', ascending: false);

    return data.map((m) => Member.fromJson(m)).toList();
  }

  Future<int> getMemberCount(String estateId) async {
    final data = await _client
        .from('members')
        .select('id')
        .eq('estate_id', estateId);

    return data.length;
  }

  Future<Member> addMember({
    required String estateId,
    required String userId,
    required String role,
    String? houseNumber,
    String? street,
  }) async {
    final data = await _client
        .from('members')
        .insert({
          'estate_id': estateId,
          'user_id': userId,
          'role': role,
          'house_number': houseNumber,
          'street': street,
        })
        .select()
        .single();

    return Member.fromJson(data);
  }

  Stream<List<Member>> watchMembers(String estateId) {
    return _client
        .from('members')
        .stream(primaryKey: ['id'])
        .eq('estate_id', estateId)
        .order('created_at', ascending: false)
        .map((data) => data.map((m) => Member.fromJson(m)).toList());
  }
}
