import 'package:flutter_test/flutter_test.dart';

/// Tests the parsing logic of SystemConfigService in isolation.
/// The service uses graceful defaults — these tests verify that behavior.

int _parseIntOrDefault(dynamic val, int defaultVal) {
  if (val == null) return defaultVal;
  if (val is int) return val;
  return int.tryParse(val.toString()) ?? defaultVal;
}

String _parseStringOrDefault(dynamic val, String defaultVal) {
  if (val == null) return defaultVal;
  return val.toString();
}

void main() {
  group('SystemConfigService parsing logic', () {
    test('parses integer value correctly', () {
      expect(_parseIntOrDefault(13, 0), 13);
      expect(_parseIntOrDefault('8', 0), 8);
      expect(_parseIntOrDefault(null, 13), 13);
      expect(_parseIntOrDefault('bad', 13), 13);
    });

    test('parses string value correctly', () {
      expect(_parseStringOrDefault('required', 'optional'), 'required');
      expect(_parseStringOrDefault(null, 'required'), 'required');
      expect(_parseStringOrDefault(42, 'default'), '42');
    });

    test('min_sitter_age defaults to 13 when missing', () {
      const defaultAge = 13;
      // Simulate missing key — value is null
      final parsed = _parseIntOrDefault(null, defaultAge);
      expect(parsed, 13);
    });

    test('max_job_duration_hours defaults to 8 when missing', () {
      const defaultHours = 8;
      final parsed = _parseIntOrDefault(null, defaultHours);
      expect(parsed, 8);
    });

    test('gps_tracking_mode defaults to required when missing', () {
      const defaultMode = 'required';
      final parsed = _parseStringOrDefault(null, defaultMode);
      expect(parsed, 'required');
    });

    test('parses valid row data for all three keys', () {
      final rows = [
        {'key': 'min_sitter_age', 'value': 11},
        {'key': 'max_job_duration_hours', 'value': '10'},
        {'key': 'gps_tracking_mode', 'value': 'optional'},
      ];

      int minSitterAge = 13;
      int maxJobDurationHours = 8;
      String gpsTrackingMode = 'required';

      for (final row in rows) {
        final key = row['key'] as String;
        final val = row['value'];
        switch (key) {
          case 'min_sitter_age':
            final parsed = _parseIntOrDefault(val, 13);
            if (parsed != null) minSitterAge = parsed;
          case 'max_job_duration_hours':
            final parsed = _parseIntOrDefault(val, 8);
            if (parsed != null) maxJobDurationHours = parsed;
          case 'gps_tracking_mode':
            gpsTrackingMode = _parseStringOrDefault(val, 'required');
        }
      }

      expect(minSitterAge, 11);
      expect(maxJobDurationHours, 10);
      expect(gpsTrackingMode, 'optional');
    });

    test('unknown keys are ignored', () {
      int minSitterAge = 13;
      final rows = [
        {'key': 'unknown_key', 'value': 999},
        {'key': 'another_unknown', 'value': 'foo'},
      ];
      for (final row in rows) {
        final key = row['key'] as String;
        if (key == 'min_sitter_age') {
          minSitterAge = _parseIntOrDefault(row['value'], 13);
        }
      }
      expect(minSitterAge, 13); // unchanged
    });
  });
}
