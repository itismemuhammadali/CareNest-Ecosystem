import 'package:supabase_flutter/supabase_flutter.dart';

/// Public sitter discovery for the family app (BACKEND.md §17 Hire screen).
class SittersRepository {
  SittersRepository(this._client);
  final SupabaseClient _client;

  /// Active, admin-approved sitters (`is_active = true`).
  Future<List<Map<String, dynamic>>> listActiveSitters({int limit = 50}) async {
    final res = await _client
        .from('sitter_profiles')
        .select(
          'user_id, bio, date_of_birth, guardian_consent_status, '
          'users!inner(full_name, email, avatar_url)',
        )
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(limit);
    final list = res as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// One sitter for profile preview (family → sitter card).
  Future<Map<String, dynamic>?> getSitterPublicBundle(String sitterUserId) async {
    final sp = await _client
        .from('sitter_profiles')
        .select(
          'user_id, bio, date_of_birth, '
          'users!inner(full_name, email, avatar_url)',
        )
        .eq('user_id', sitterUserId)
        .eq('is_active', true)
        .maybeSingle();
    if (sp == null) return null;
    return Map<String, dynamic>.from(sp as Map);
  }
}
