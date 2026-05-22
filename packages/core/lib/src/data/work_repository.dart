import 'package:supabase_flutter/supabase_flutter.dart';

/// Clock in/out RPCs (BACKEND.md §7 — `clock_in` / `clock_out`).
class WorkRepository {
  WorkRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> clockIn({
    required String hireId,
    required double lat,
    required double lng,
  }) async {
    final res = await _client.rpc(
      'clock_in',
      params: {
        'p_hire_id': hireId,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{'raw': res};
  }

  Future<Map<String, dynamic>> clockOut({
    required String hireId,
    required double lat,
    required double lng,
  }) async {
    final res = await _client.rpc(
      'clock_out',
      params: {
        'p_hire_id': hireId,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{'raw': res};
  }

  /// Hire id where job is `hired` and sitter has no open time entry.
  Future<String?> hireIdAwaitingClockIn() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final hires = await _client.from('hires').select('id, job_id').eq('sitter_id', uid);
    final list = List<Map<String, dynamic>>.from(
      (hires as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    for (final h in list) {
      final jobId = h['job_id']?.toString();
      if (jobId == null) continue;
      final job = await _client.from('jobs').select('status').eq('id', jobId).maybeSingle();
      if (job == null) continue;
      final status = (job as Map)['status']?.toString();
      if (status != 'hired') continue;
      final hireId = h['id']?.toString();
      if (hireId == null) continue;
      final entries = await _client
          .from('time_entries')
          .select('id, clock_out_at')
          .eq('hire_id', hireId);
      final hasOpen = (entries as List).cast<Map>().any((e) => e['clock_out_at'] == null);
      if (!hasOpen) return hireId;
    }
    return null;
  }

  /// Hire id with an open time entry (job should be `active`).
  Future<String?> hireIdWithOpenClockIn() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final entries =
        await _client.from('time_entries').select('hire_id, clock_out_at').eq('sitter_id', uid);
    for (final e in entries as List) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['clock_out_at'] == null) return m['hire_id']?.toString();
    }
    return null;
  }
}
