import 'package:intl/intl.dart';

/// Display model for one row from [JobsRepository.openJobs].
class OpenJobRowUi {
  OpenJobRowUi({
    required this.jobId,
    required this.familyName,
    required this.location,
    required this.dateDisplay,
    required this.hoursDisplay,
    required this.childrenCount,
    required this.wageDisplay,
    required this.totalWageDisplay,
    required this.description,
    required this.tags,
    required this.detailDate,
    required this.detailDuration,
    required this.detailChildrenLabel,
  });

  final String jobId;
  final String familyName;
  final String location;
  final String dateDisplay;
  final String hoursDisplay;
  final int childrenCount;
  final String wageDisplay;
  final String totalWageDisplay;
  final String description;
  final List<String> tags;
  final String detailDate;
  final String detailDuration;
  final String detailChildrenLabel;

  static OpenJobRowUi fromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final addr = row['location_address'];
    var location = 'Location on file';
    if (addr is Map && addr['formatted'] != null) {
      location = addr['formatted'].toString();
    }
    final desc = (row['description']?.toString().trim().isNotEmpty ?? false)
        ? row['description'].toString()
        : 'Open babysitting shift — details from the family.';
    final nocRaw = row['number_of_children'];
    final noc = nocRaw is int
        ? nocRaw
        : int.tryParse(nocRaw?.toString() ?? '1') ?? 1;

    final dateStr = row['date']?.toString() ?? '';
    DateTime? day;
    if (dateStr.length >= 10) {
      day = DateTime.tryParse(dateStr.substring(0, 10));
    } else {
      day = DateTime.tryParse(dateStr);
    }
    final dateDisplay =
        day != null ? DateFormat.yMMMd().format(day) : (dateStr.isEmpty ? '—' : dateStr);

    final start =
        row['start_time'] != null ? DateTime.tryParse(row['start_time'].toString()) : null;
    final end = row['end_time'] != null ? DateTime.tryParse(row['end_time'].toString()) : null;
    final hoursDisplay = (start != null && end != null)
        ? '${end.difference(start).inHours}h'
        : '—';
    final detailDuration = (start != null && end != null)
        ? '${DateFormat.jm('en_US').format(start.toLocal())} - ${DateFormat.jm('en_US').format(end.toLocal())}'
        : hoursDisplay;

    final childrenLabel = noc == 1 ? '1 child' : '$noc children';
    final tags = <String>[childrenLabel, 'Open'];

    return OpenJobRowUi(
      jobId: id,
      familyName: 'Verified family',
      location: location,
      dateDisplay: dateDisplay,
      hoursDisplay: hoursDisplay,
      childrenCount: noc,
      wageDisplay: '— / hr',
      totalWageDisplay: 'Set at booking',
      description: desc,
      tags: tags,
      detailDate: dateDisplay,
      detailDuration: detailDuration,
      detailChildrenLabel: childrenLabel,
    );
  }
}
