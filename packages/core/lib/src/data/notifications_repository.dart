import 'package:supabase_flutter/supabase_flutter.dart';

/// In-app notifications (BACKEND.md §5 Migration 10).
class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> myNotifications() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid);
  }

  Future<void> markRead(String notificationId) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', notificationId);
  }

  Future<void> markAllRead() async {
    await _client.rpc('mark_all_notifications_read');
  }
}
