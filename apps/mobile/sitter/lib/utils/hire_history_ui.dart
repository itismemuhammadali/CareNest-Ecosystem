import 'package:intl/intl.dart';

/// Maps [JobsRepository.sitterHireHistoryWithJobs] rows to the UI shape used by [JobHistoryScreen].
class HireHistoryUi {
  static Map<String, dynamic> jobCardFromHire(Map<String, dynamic> hire) {
    final jobRaw = hire['jobs'];
    final job = jobRaw is Map
        ? Map<String, dynamic>.from(jobRaw)
        : <String, dynamic>{};

    final title = (job['title'] ?? 'Completed shift').toString();
    
    final familyUser = job['users'] as Map?;
    final familyName = familyUser?['full_name']?.toString() ?? title;

    final dateStr = job['date']?.toString() ?? '';
    DateTime? day;
    if (dateStr.length >= 10) {
      day = DateTime.tryParse(dateStr.substring(0, 10));
    } else {
      day = DateTime.tryParse(dateStr);
    }
    final dateDisplay = day != null
        ? DateFormat.yMMMd().format(day)
        : (dateStr.isEmpty ? '—' : dateStr);
    final monthLabel = day != null ? DateFormat('MMMM').format(day) : '';

    final start = job['start_time'] != null
        ? DateTime.tryParse(job['start_time'].toString())
        : null;
    final end = job['end_time'] != null
        ? DateTime.tryParse(job['end_time'].toString())
        : null;
    double hours = 0;
    if (start != null && end != null) {
      hours = end.difference(start).inMinutes / 60.0;
    }

    final rate = double.tryParse(hire['hourly_rate']?.toString() ?? '') ?? 0;
    final rateStr = rate > 0 ? '\$${rate.toStringAsFixed(2)}/hr' : '—';

    final earned = hours * rate;
    final earnedStr = '\$${earned.toStringAsFixed(2)}';

    final status = (job['status'] ?? 'completed').toString();

    return <String, dynamic>{
      'family': familyName,
      'date': dateDisplay,
      'hours': hours.toStringAsFixed(1),
      'rate': rateStr,
      'earned': earnedStr,
      'status': status,
      'month': monthLabel,
    };
  }

  static ({double totalHours, double totalEarned}) totals(
    List<Map<String, dynamic>> cards,
  ) {
    var th = 0.0;
    var te = 0.0;
    for (final j in cards) {
      th += double.tryParse(j['hours']?.toString() ?? '0') ?? 0;
      final e = (j['earned'] ?? '').toString();
      te += double.tryParse(e.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    return (totalHours: th, totalEarned: te);
  }
}
