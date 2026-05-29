import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../validation/onboarding_parse.dart';

/// Reads `users`, `family_profiles`, `sitter_profiles` (BACKEND.md §5).
class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>?> currentUserRow() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client.from('users').select().eq('id', uid).maybeSingle();
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> familyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('family_profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> sitterProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('sitter_profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }

  Future<void> updateFamily({
    Map<String, dynamic>? homeAddress,
    double? homeLat,
    double? homeLng,
    String? homeSafetyInfo,
    Map<String, dynamic>? emergencyContact,
    Map<String, dynamic>? babysitterPrefs,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final payload = <String, dynamic>{
      if (homeAddress != null) 'home_address': homeAddress,
      if (homeLat != null) 'home_lat': homeLat,
      if (homeLng != null) 'home_lng': homeLng,
      if (homeSafetyInfo != null) 'home_safety_info': homeSafetyInfo,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (babysitterPrefs != null) 'babysitter_prefs': babysitterPrefs,
    };
    if (payload.isEmpty) return;
    await _client.from('family_profiles').update(payload).eq('user_id', uid);
  }

  Future<void> updateSitterBio(String bio) async {
    if (bio.length > 500) throw ArgumentError('Bio must be 500 characters or less');
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client.from('sitter_profiles').update({'bio': bio}).eq('user_id', uid);
  }

  /// Parses family onboarding "number of children" + comma-separated ages into DB rows.
  static List<Map<String, Object>> parseOnboardingChildrenRecords({
    required String countStr,
    required String agesStr,
  }) =>
      parseFamilyOnboardingChildrenRecords(countStr: countStr, agesStr: agesStr);

  /// Replaces all `children` rows for the signed-in family (RLS: family_id = auth.uid()).
  Future<void> replaceFamilyChildren(List<Map<String, Object>> rows) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client.from('children').delete().eq('family_id', uid);
    if (rows.isEmpty) return;
    await _client.from('children').insert(
          rows
              .map(
                (r) => {
                  'family_id': uid,
                  'name': r['name'],
                  'age': r['age'],
                },
              )
              .toList(),
        );
  }

  /// Shallow-merge [patch] into existing `family_profiles.babysitter_prefs`.
  Future<void> mergeFamilyBabysitterPrefs(Map<String, dynamic> patch) async {
    final row = await familyProfile();
    final base = Map<String, dynamic>.from(
      (row?['babysitter_prefs'] is Map)
          ? Map<String, dynamic>.from(row!['babysitter_prefs'] as Map)
          : <String, dynamic>{},
    );
    base.addAll(patch);
    await updateFamily(babysitterPrefs: base);
  }

  /// Inserts guardian consent once per sitter (unique on sitter_id). Webhook sends email.
  Future<void> ensureGuardianConsentRow({
    required String guardianName,
    required String guardianEmail,
    String? guardianPhone,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final existing =
        await _client.from('guardian_consents').select('id').eq('sitter_id', uid).maybeSingle();
    if (existing != null) return;
    await _client.from('guardian_consents').insert({
      'sitter_id': uid,
      'guardian_name': guardianName.trim(),
      'guardian_email': guardianEmail.trim(),
      if (guardianPhone != null && guardianPhone.trim().isNotEmpty)
        'guardian_phone': guardianPhone.trim(),
    });
  }

  /// Uploads bytes to `bg-check-docs/<userId>/...` (RLS folder = auth uid).
  Future<String> uploadFamilyBgCheckBytes(Uint8List bytes, String filename) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final safe = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _client.storage.from('bg-check-docs').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Submits background-check documents and sets family `bg_check_status` to pending (BACKEND.md §7 RPC).
  Future<void> submitBackgroundCheck(List<dynamic> documents) async {
    if (_client.auth.currentUser == null) throw StateError('Not signed in');
    await _client.rpc('family_submit_background_check', params: {
      'p_documents': documents,
    });
  }

  /// Submits or re-submits (after rejection) a course certification for the signed-in sitter.
  /// Use only when a real published `courses` row exists; keep apps unwired until then.
  Future<void> submitCertification({
    required String courseId,
    num? score,
    int? questionsAnswered,
    int? correctAnswers,
    int? timeTakenSeconds,
  }) async {
    if (_client.auth.currentUser == null) throw StateError('Not signed in');
    await _client.rpc('sitter_submit_certification', params: {
      'p_course_id': courseId,
      'p_score': score,
      'p_questions_answered': questionsAnswered,
      'p_correct_answers': correctAnswers,
      'p_time_taken_seconds': timeTakenSeconds,
    });
  }

  /// Lists `children` rows for the signed-in family (newest first).
  Future<List<Map<String, dynamic>>> listFamilyChildren() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('children')
        .select()
        .eq('family_id', uid)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(
      (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// Emits the signed-in sitter's profile row whenever it changes (for `is_active` gating).
  Stream<Map<String, dynamic>?> watchSitterProfileRow() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<Map<String, dynamic>?>.empty();
    }
    return _client
        .from('sitter_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Map<String, dynamic>.from(rows.first as Map);
        });
  }

  /// Emits the signed-in family's profile row (e.g. `bg_check_status` UI banners).
  Stream<Map<String, dynamic>?> watchFamilyProfileRow() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<Map<String, dynamic>?>.empty();
    }
    return _client
        .from('family_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Map<String, dynamic>.from(rows.first as Map);
        });
  }

  /// Updates `public.users` fields allowed from the client (RLS: own row).
  Future<void> updateCurrentUser({
    String? fullName,
    String? phone,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final payload = <String, dynamic>{
      if (fullName != null) 'full_name': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
    };
    if (payload.isEmpty) return;
    await _client.from('users').update(payload).eq('id', uid);
  }

  Future<void> updateSitterAddress(Map<String, dynamic> address) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client
        .from('sitter_profiles')
        .update({'home_address': address})
        .eq('user_id', uid);
  }

  Future<void> updateSitterEmergencyContact(
      Map<String, dynamic> contact) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client
        .from('sitter_profiles')
        .update({'emergency_contact': contact})
        .eq('user_id', uid);
  }

  Future<Map<String, dynamic>> getSitterPreferences() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final res = await _client
        .from('sitter_profiles')
        .select('preferences')
        .eq('user_id', uid)
        .maybeSingle();
    if (res == null) return {};
    final prefs = res['preferences'];
    return prefs is Map ? Map<String, dynamic>.from(prefs) : {};
  }

  Future<void> saveSitterPreferences(Map<String, dynamic> prefs) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client
        .from('sitter_profiles')
        .update({'preferences': prefs})
        .eq('user_id', uid);
  }

  Future<Map<String, dynamic>> getFamilyPrivacySettings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final res = await _client
        .from('family_profiles')
        .select('privacy_settings')
        .eq('user_id', uid)
        .maybeSingle();
    if (res == null) return {};
    final settings = res['privacy_settings'];
    return settings is Map ? Map<String, dynamic>.from(settings) : {};
  }

  Future<void> saveFamilyPrivacySettings(Map<String, dynamic> settings) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    await _client
        .from('family_profiles')
        .update({'privacy_settings': settings})
        .eq('user_id', uid);
  }

  /// Uploads [bytes] to the public `avatars` bucket and saves the public URL to `users.avatar_url`.
  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpg';
    final path = '$uid/avatar.$ext';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
        );
    final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
    // Append a cache-busting timestamp so Flutter's NetworkImage always
    // fetches the latest image instead of serving a stale cached version.
    final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('users').update({'avatar_url': url}).eq('id', uid);
    return url;
  }
}
