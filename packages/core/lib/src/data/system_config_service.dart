import 'package:supabase_flutter/supabase_flutter.dart';

class SystemConfigService {
  SystemConfigService(this._client);
  final SupabaseClient _client;

  int minSitterAge = 13;
  int maxJobDurationHours = 8;
  String gpsTrackingMode = 'required';

  Future<void> load() async {
    try {
      final rows = await _client.from('system_config').select('key, value');
      for (final row in (rows as List)) {
        final key = row['key'] as String?;
        final val = row['value'];
        switch (key) {
          case 'min_sitter_age':
            final parsed = val is int ? val : int.tryParse(val?.toString() ?? '');
            if (parsed != null) minSitterAge = parsed;
          case 'max_job_duration_hours':
            final parsed = val is int ? val : int.tryParse(val?.toString() ?? '');
            if (parsed != null) maxJobDurationHours = parsed;
          case 'gps_tracking_mode':
            if (val != null) gpsTrackingMode = val.toString();
        }
      }
    } catch (_) {
      // Use defaults on any network or parse error
    }
  }
}
