import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class NotificationRepository {
  final _client = SupabaseConfig.client;

  Future<List<AppNotification>> getNotifications() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return data.map((n) => AppNotification.fromJson(n)).toList();
  }

  Future<int> getUnreadCount() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return 0;

    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return data.length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  /// Real-time stream of notifications — pushes new ones instantly
  Stream<List<AppNotification>> watchNotifications() {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((n) => AppNotification.fromJson(n)).toList());
  }

  /// Real-time stream of unread count
  Stream<int> watchUnreadCount() {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.where((n) => n['is_read'] == false).length);
  }

  /// Send a notification (used internally by other features)
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    String? estateId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'estate_id': estateId,
    });
  }

  /// Send notification to all members of an estate
  Future<void> sendEstateNotification({
    required String estateId,
    required String type,
    required String title,
    String? body,
  }) async {
    final members = await _client
        .from('members')
        .select('user_id')
        .eq('estate_id', estateId);

    for (final member in members) {
      await sendNotification(
        userId: member['user_id'],
        type: type,
        title: title,
        body: body,
        estateId: estateId,
      );
    }
  }
}
