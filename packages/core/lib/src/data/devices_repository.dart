import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM device rows (`public.devices`, BACKEND.md §14).
class DevicesRepository {
  DevicesRepository(this._client);
  final SupabaseClient _client;

  /// Upserts one row per (user_id, fcm_token). Safe to call on login and on token refresh.
  Future<void> registerFcmToken({
    required String token,
    String platform = 'android',
  }) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    await _client.from('devices').upsert(
      <String, dynamic>{
        'user_id': u.id,
        'fcm_token': token,
        'platform': platform,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,fcm_token',
    );
  }
}
