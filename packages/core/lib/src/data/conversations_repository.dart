import 'package:supabase_flutter/supabase_flutter.dart';

/// Job-linked conversations (BACKEND.md §5 Migration 8).
class ConversationsRepository {
  ConversationsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> familyConversations() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('family_id', uid);
  }

  Stream<List<Map<String, dynamic>>> sitterConversations() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('sitter_id', uid);
  }

  Future<String?> conversationIdForJob(String jobId) async {
    final res = await _client
        .from('conversations')
        .select('id')
        .eq('job_id', jobId)
        .maybeSingle();
    if (res == null) return null;
    return (res as Map)['id']?.toString();
  }

  Future<Map<String, dynamic>?> fetchJobTitle(String jobId) async {
    final res = await _client.from('jobs').select('title').eq('id', jobId).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  /// Returns the count of messages sent by others (not current user) that are unread.
  Future<int> unreadCountForConversation(String conversationId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final res = await _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', uid)
        .isFilter('read_at', null);
    return (res as List).length;
  }
}
