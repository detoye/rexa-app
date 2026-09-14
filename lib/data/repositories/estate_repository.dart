import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class EstateRepository {
  final _client = SupabaseConfig.client;

  Future<Estate?> getCurrentEstate() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final member = await _client
        .from('members')
        .select('estate_id, estates(*)')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (member == null || member['estates'] == null) return null;

    return Estate.fromJson(member['estates'] as Map<String, dynamic>);
  }

  Future<List<Estate>> getEstatesForUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('members')
        .select('estates(*)')
        .eq('user_id', user.id);

    return data
        .map((m) => m['estates'])
        .where((e) => e != null)
        .map<Estate>((e) => Estate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Estate> createEstate({
    required String name,
    required String address,
    String? description,
  }) async {
    final user = _client.auth.currentUser!;
    final data = await _client
        .from('estates')
        .insert({
          'name': name,
          'address': address,
          'description': description,
          'created_by': user.id,
        })
        .select()
        .single();

    return Estate.fromJson(data);
  }

  Future<Estate> createEstateWithAdmin({
    required String name,
    required String address,
    String? description,
  }) async {
    final user = _client.auth.currentUser!;

    // 1. Grant platform admin access first (required for estates INSERT policy)
    await _client.from('platform_admins').insert({
      'id': user.id,
      'role': 'admin',
    });

    // 2. Create the estate
    final estateData = await _client
        .from('estates')
        .insert({
          'name': name,
          'address': address,
          'description': description,
          'created_by': user.id,
        })
        .select()
        .single();

    final estate = Estate.fromJson(estateData);

    // 3. Create member record linking user to estate
    await _client.from('members').insert({
      'user_id': user.id,
      'estate_id': estate.id,
      'role': 'admin',
      'is_verified': true,
    });

    return estate;
  }

  Stream<List<Estate>> watchEstates() {
    return _client.from('estates').stream(primaryKey: ['id']).map(
        (data) => data.map((e) => Estate.fromJson(e)).toList());
  }
}
