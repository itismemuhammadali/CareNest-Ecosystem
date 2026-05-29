import 'package:supabase_flutter/supabase_flutter.dart';

/// Sitter-side application + family-side review (BACKEND.md §7 RPCs).
class ApplicationsRepository {
  ApplicationsRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> createApplication({
    required String jobId,
    String? coverMessage,
  }) async {
    final res = await _client.rpc(
      'create_application',
      params: {
        'p_job_id': jobId,
        'p_cover_message': coverMessage,
      },
    );
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{'raw': res};
  }

  Future<void> withdraw(String applicationId) async {
    await _client.rpc(
      'withdraw_application',
      params: {'p_application_id': applicationId},
    );
  }

  Future<String> hire(String applicationId) async {
    final res = await _client.rpc(
      'create_hire',
      params: {'p_application_id': applicationId},
    );
    return res.toString();
  }

  /// Family-side direct hire: creates job + application + hire atomically.
  /// Used when the family browses sitters and hires without an existing job posting.
  Future<Map<String, dynamic>> directHire({
    required String sitterId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    int numberOfChildren = 1,
    String title = 'Direct hire',
  }) async {
    final res = await _client.rpc(
      'family_direct_hire',
      params: {
        'p_sitter_id': sitterId,
        'p_date': date.toIso8601String().substring(0, 10),
        'p_start_time': startTime.toUtc().toIso8601String(),
        'p_end_time': endTime.toUtc().toIso8601String(),
        'p_num_children': numberOfChildren,
        'p_title': title,
      },
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{'raw': res};
  }

  /// Stream of applications for one job (family review screen).
  Stream<List<Map<String, dynamic>>> applicationsForJob(String jobId) {
    return _client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('job_id', jobId);
  }

  /// One-shot list with `jobs` map per row for the sitter's applications feed.
  Future<List<Map<String, dynamic>>> fetchMyApplicationsWithJobs() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('applications')
        .select(
          'id, job_id, sitter_id, status, applied_at, cover_message, '
          'jobs(id, title, description, date, start_time, end_time, status, '
          'number_of_children, location_address, family_id, '
          'family_profiles!inner(user_id, users!inner(full_name, avatar_url)))',
        )
        .eq('sitter_id', uid)
        .order('applied_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// All applications submitted by the signed-in sitter.
  Stream<List<Map<String, dynamic>>> mySitterApplications() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('sitter_id', uid);
  }

  /// One-shot list with `sitter_user` map (`full_name`, `email`, `avatar_url`) per row.
  Future<List<Map<String, dynamic>>> applicationsWithSitterUsers(
    String jobId,
  ) async {
    final apps = await _client
        .from('applications')
        .select()
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(
      (apps as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    if (list.isEmpty) return list;
    final ids = list.map((e) => e['sitter_id'].toString()).toSet().toList();
    final usersRes =
        await _client.from('users').select('id, full_name, email, avatar_url').filter('id', 'in', '(${ids.join(',')})');
    final users = List<Map<String, dynamic>>.from(
      (usersRes as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final byId = {for (final u in users) u['id'] as String: u};
    for (final a in list) {
      final sid = a['sitter_id']?.toString();
      a['sitter_user'] = sid != null ? (byId[sid] ?? <String, dynamic>{}) : <String, dynamic>{};
    }
    return list;
  }
}
