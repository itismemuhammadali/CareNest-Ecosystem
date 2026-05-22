import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime chat (BACKEND.md §13). Tables added to supabase_realtime
/// publication in migration 20260209100018.
class MessagesRepository {
  MessagesRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> stream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId);
  }

  Future<void> send({
    required String conversationId,
    required String body,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Sign in required to send a message');
    }
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body,
    });
  }

  Future<void> markRead(String messageId) async {
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', messageId);
  }
}
