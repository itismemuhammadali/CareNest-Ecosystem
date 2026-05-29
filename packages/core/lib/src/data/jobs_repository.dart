import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes jobs (BACKEND.md §5 jobs / §17 wiring map).
///
/// Schema columns (see migration 20260209100006_marketplace.sql):
///   id, family_id, title, description, date, start_time, end_time,
///   number_of_children, child_ids, location_lat, location_lng,
///   location_address (jsonb), geofence_radius_m, status.
class JobsRepository {
  JobsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> myFamilyJobs() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('family_id', uid);
  }

  Future<List<Map<String, dynamic>>> openJobs({int limit = 50}) async {
    final res = await _client
        .from('jobs')
        .select(
          'id, title, description, date, start_time, end_time, '
          'number_of_children, location_address, status, family_id, created_at, '
          'family_profiles!inner(user_id, users!inner(full_name, avatar_url))',
        )
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> createJob({
    required String title,
    String? description,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int numberOfChildren,
    required double locationLat,
    required double locationLng,
    Map<String, dynamic> locationAddress = const {},
    int geofenceRadiusM = 150,
    List<String> childIds = const [],
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Sign in required to post a job');
    }
    final payload = <String, dynamic>{
      'family_id': uid,
      'title': title,
      'description': description,
      'date': date.toIso8601String().substring(0, 10),
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'number_of_children': numberOfChildren,
      'child_ids': childIds,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_address': locationAddress,
      'geofence_radius_m': geofenceRadiusM,
      'status': 'open',
    };
    final res = await _client.from('jobs').insert(payload).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> cancelJob(String jobId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in required to cancel a job');
    final updated = await _client
        .from('jobs')
        .update({'status': 'cancelled'})
        .eq('id', jobId)
        .eq('family_id', uid)
        .select('id');
    if ((updated as List).isEmpty) {
      throw StateError('Job not found or you do not own it');
    }
  }

  Future<Map<String, dynamic>?> getJob(String jobId) async {
    final res = await _client.from('jobs').select().eq('id', jobId).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> hireForJob(String jobId) async {
    final res = await _client.from('hires').select().eq('job_id', jobId).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<double?> hourlyRateForAge(int age) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await _client
        .from('age_wage_tiers')
        .select('hourly_rate, min_age, max_age, effective_from')
        .lte('min_age', age)
        .gte('max_age', age)
        .lte('effective_from', today)
        .order('effective_from', ascending: false)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(res as List);
    if (list.isEmpty) return null;
    return double.tryParse(list.first['hourly_rate'].toString());
  }

  Future<int> countMySitterApplications() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final res = await _client
        .from('applications')
        .select('id')
        .eq('sitter_id', uid);
    return (res as List).length;
  }

  /// Sitter hire history with nested `jobs` row (BACKEND.md §17 job history).
  Future<List<Map<String, dynamic>>> sitterHireHistoryWithJobs() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('hires')
        .select(
          'id, job_id, sitter_id, hourly_rate, hired_at, '
          'jobs(id, title, description, date, start_time, end_time, status, '
          'number_of_children, location_address, family_id, '
          'family_profiles!inner(user_id, users!inner(full_name, avatar_url)))',
        )
        .eq('sitter_id', uid)
        .order('hired_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }
}
