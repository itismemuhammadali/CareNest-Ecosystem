import 'dart:convert';

import 'package:http/http.dart' as http;

/// In-memory draft for the post-job wizard (steps 1–4).
class JobPostSession {
  JobPostSession._();

  static String description = '';
  static String dateStr = '';
  static String startTimeStr = '';
  static String endTimeStr = '';
  static String specialRequirements = '';
  static String address = '';

  /// Pre-resolved coordinates (set when user picks home address or GPS).
  /// When non-null, step 4 skips Nominatim geocoding entirely.
  static double? cachedLat;
  static double? cachedLng;

  /// Geofence radius in metres for clock-in verification (100–500m, default 150m).
  static int geofenceRadiusM = 150;

  /// Parsed from step 1; defaults to 2 if invalid.
  static int numberOfChildren = 2;

  /// IDs of family children selected for this job. Empty = all children.
  static List<String> selectedChildIds = [];

  static String get combinedDescription {
    final desc = description.trim();
    final spec = specialRequirements.trim();
    if (spec.isEmpty) return desc;
    if (desc.isEmpty) return spec;
    return '$desc\n\nSpecial requirements:\n$spec';
  }

  static void clear() {
    description = '';
    dateStr = '';
    startTimeStr = '';
    endTimeStr = '';
    specialRequirements = '';
    address = '';
    cachedLat = null;
    cachedLng = null;
    numberOfChildren = 2;
    geofenceRadiusM = 150;
    selectedChildIds = [];
  }

  /// Parses `mm/dd/yyyy` (also accepts `-` or `.` separators).
  static DateTime? parseUsDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'[/.\-]'));
    if (parts.length != 3) return null;
    final m = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (m == null || d == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  /// Combines [date] with a time string in `"9:27 PM"` or `"21:27"` format.
  static DateTime? combineDateAndTime(DateTime date, String timeRaw) {
    final trimmed = timeRaw.trim();
    if (trimmed.isEmpty) return null;
    // "9:27 PM" / "12:00 AM" — avoid DateFormat.jm which needs locale init on web
    final ampm = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(trimmed);
    if (ampm != null) {
      int h = int.parse(ampm.group(1)!);
      final min = int.parse(ampm.group(2)!);
      final isPm = ampm.group(3)!.toUpperCase() == 'PM';
      if (isPm && h != 12) h += 12;
      if (!isPm && h == 12) h = 0;
      return DateTime(date.year, date.month, date.day, h, min);
    }
    // 24-hour "21:27"
    final h24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (h24 != null) {
      final h = int.parse(h24.group(1)!);
      final min = int.parse(h24.group(2)!);
      return DateTime(date.year, date.month, date.day, h, min);
    }
    return null;
  }

  /// Title for `jobs.title` (DB: 5–200 chars).
  static String buildTitle() {
    var t = description.trim().split('\n').first.trim();
    if (t.isEmpty) t = 'Family babysitting';
    if (t.length < 5) {
      final suffix = dateStr.trim().isEmpty ? ' job' : ' (${dateStr.trim()})';
      t = '$t$suffix';
    }
    if (t.length > 200) t = t.substring(0, 200);
    return t;
  }

  /// Resolves coordinates for publishing.
  /// Returns cached coords if set (home address / GPS), otherwise geocodes via Nominatim.
  static Future<(double, double)> resolveCoords() async {
    if (cachedLat != null && cachedLng != null) {
      return (cachedLat!, cachedLng!);
    }
    return geocodeAddress(address);
  }

  /// Geocodes [address] using Nominatim (OSM). Returns [lat, lng] or [0.0, 0.0] on failure.
  static Future<(double, double)> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return (0.0, 0.0);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address.trim(),
        'format': 'json',
        'limit': '1',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'StarSittersFamilyApp/1.0'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return (0.0, 0.0);
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isNotEmpty) {
        final lat = double.tryParse(results[0]['lat'].toString()) ?? 0.0;
        final lng = double.tryParse(results[0]['lon'].toString()) ?? 0.0;
        return (lat, lng);
      }
    } catch (_) {}
    return (0.0, 0.0);
  }

  /// Returns a user-facing message if the draft cannot be published.
  static String? validateForPublish() {
    if (description.trim().isEmpty) {
      return 'Please enter a job description.';
    }
    final day = parseUsDate(dateStr);
    if (day == null) {
      return 'Please enter a valid date (mm/dd/yyyy).';
    }
    final start = combineDateAndTime(day, startTimeStr);
    final end = combineDateAndTime(day, endTimeStr);
    if (start == null || end == null) {
      return 'Please enter start and end times (e.g. 6:00 PM).';
    }
    if (!end.isAfter(start)) {
      return 'End time must be after start time.';
    }
    if (address.trim().isEmpty && cachedLat == null) {
      return 'Please select a location on the location step.';
    }
    if (numberOfChildren < 1 || numberOfChildren > 10) {
      return 'Number of children must be between 1 and 10.';
    }
    return null;
  }
}
