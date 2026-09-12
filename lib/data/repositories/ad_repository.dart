import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class AdRepository {
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

  Future<List<MemberAd>> getActiveAds(String estateId) async {
    final data = await _client
        .from('member_ads')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return data.map((a) => MemberAd.fromJson(a)).toList();
  }

  Future<MemberAd> createAd({
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    final data = await _client
        .from('member_ads')
        .insert({
          'member_id': SupabaseConfig.auth.currentUser!.id,
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'is_active': true,
        })
        .select()
        .single();

    return MemberAd.fromJson(data);
  }

  Future<void> deactivateAd(String adId) async {
    await _client.from('member_ads').update({'is_active': false}).eq('id', adId);
  }
}
