import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class GovernanceRepository {
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

  Future<List<Committee>> getCommittees(String estateId) async {
    final data = await _client
        .from('committees')
        .select()
        .eq('estate_id', estateId)
        .order('created_at', ascending: false);

    return data.map((c) => Committee.fromJson(c)).toList();
  }

  Future<List<Meeting>> getMeetings(String estateId) async {
    final data = await _client
        .from('meetings')
        .select()
        .eq('estate_id', estateId)
        .order('meeting_date', ascending: false)
        .limit(10);

    return data.map((m) => Meeting.fromJson(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getProjects(String estateId) async {
    final data = await _client
        .from('projects')
        .select('id, name, description, budget, spent, progress, status, created_at')
        .eq('estate_id', estateId)
        .order('created_at', ascending: false);

    return data;
  }

  Future<int> getCommitteeMemberCount(String committeeId) async {
    final data = await _client
        .from('committee_members')
        .select('id')
        .eq('committee_id', committeeId);

    return data.length;
  }

  Future<Committee> createCommittee({
    required String estateId,
    required String name,
    String? description,
  }) async {
    final data = await _client
        .from('committees')
        .insert({
          'estate_id': estateId,
          'name': name,
          'description': description,
        })
        .select()
        .single();

    return Committee.fromJson(data);
  }

  Future<Meeting> createMeeting({
    required String estateId,
    required String title,
    required DateTime meetingDate,
    String? minutes,
  }) async {
    final data = await _client
        .from('meetings')
        .insert({
          'estate_id': estateId,
          'title': title,
          'meeting_date': meetingDate.toIso8601String(),
          'minutes': minutes,
        })
        .select()
        .single();

    return Meeting.fromJson(data);
  }
}
