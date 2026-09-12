import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class AnnouncementRepository {
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

  Future<List<Announcement>> getAnnouncements(String estateId) async {
    final data = await _client
        .from('announcements')
        .select()
        .eq('estate_id', estateId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return data.map((a) => Announcement.fromJson(a)).toList();
  }

  Future<Announcement> createAnnouncement({
    required String estateId,
    required String title,
    required String content,
    String priority = 'normal',
    String category = 'general',
    bool isPinned = false,
  }) async {
    final data = await _client
        .from('announcements')
        .insert({
          'estate_id': estateId,
          'title': title,
          'content': content,
          'priority': priority,
          'category': category,
          'is_pinned': isPinned,
        })
        .select()
        .single();

    return Announcement.fromJson(data);
  }

  Future<void> pinAnnouncement(String id, bool isPinned) async {
    await _client.from('announcements').update({
      'is_pinned': isPinned,
    }).eq('id', id);
  }

  Stream<List<Announcement>> watchAnnouncements(String estateId) {
    return _client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('estate_id', estateId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .map((data) => data.map((a) => Announcement.fromJson(a)).toList());
  }
}
