import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'jobs_details_screen.dart';
import 'post_new_job_step1_screen.dart';

class MyPostedJobsScreen extends StatefulWidget {
  const MyPostedJobsScreen({super.key});

  @override
  State<MyPostedJobsScreen> createState() => _MyPostedJobsScreenState();
}

class _MyPostedJobsScreenState extends State<MyPostedJobsScreen> {
  /// `all` | `open` | `filled` | `done`
  String _filter = 'all';

  static String _uiStatus(Map<String, dynamic> row) {
    final s = row['status']?.toString() ?? '';
    if (s == 'open') return 'Open';
    if (s == 'hired' || s == 'active') return 'Filled';
    if (s == 'completed') return 'Done';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'draft') return 'Draft';
    return s.isEmpty ? '—' : s;
  }

  static String _infoLine(Map<String, dynamic> row) {
    final s = row['status']?.toString() ?? '';
    switch (s) {
      case 'open':
        return 'Open for applications';
      case 'hired':
        return 'Sitter hired';
      case 'active':
        return 'Job in progress';
      case 'completed':
        return 'Job completed';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft — not visible to sitters';
      default:
        return s;
    }
  }

  static String _postedLine(Map<String, dynamic> row) {
    final raw = row['created_at']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return 'Posted ${DateFormat.yMMMd().add_jm().format(dt.toLocal())}';
  }

  static String _dateTimeLine(Map<String, dynamic> row) {
    final dateStr = row['date']?.toString();
    final startRaw = row['start_time']?.toString();
    final endRaw = row['end_time']?.toString();
    if (dateStr == null) return '—';
    final start = startRaw != null ? DateTime.tryParse(startRaw) : null;
    final end = endRaw != null ? DateTime.tryParse(endRaw) : null;
    DateTime? d;
    if (dateStr.length >= 10) {
      d = DateTime.tryParse(dateStr.substring(0, 10));
    } else {
      d = DateTime.tryParse(dateStr);
    }
    final dateOut = d != null ? DateFormat.yMMMd().format(d) : dateStr;
    if (start != null && end != null) {
      final t = '${DateFormat.jm().format(start.toLocal())} - ${DateFormat.jm().format(end.toLocal())}';
      return '$dateOut\n$t';
    }
    return dateOut;
  }

  bool _passesFilter(Map<String, dynamic> row) {
    final s = row['status']?.toString() ?? '';
    switch (_filter) {
      case 'open':
        return s == 'open';
      case 'filled':
        return s == 'hired' || s == 'active';
      case 'done':
        return s == 'completed';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = JobsRepository(Supabase.instance.client);
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const Header2(title: 'My Posted Jobs'),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.myFamilyJobs(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load jobs: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                  final all = snapshot.data ?? const <Map<String, dynamic>>[];
                  final filtered = all.where(_passesFilter).toList();
                  final openN = all.where((r) => r['status'] == 'open').length;
                  final filledN = all.where((r) => r['status'] == 'hired' || r['status'] == 'active').length;
                  final doneN = all.where((r) => r['status'] == 'completed').length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PostNewJobStep1Screen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA8D8EA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '+ Post New Job',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('$openN', 'Open')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('$filledN', 'Filled')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('$doneN', 'Done')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterTab('All Jobs', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterTab('Open ($openN)', 'open'),
                              const SizedBox(width: 8),
                              _buildFilterTab('Filled', 'filled'),
                              const SizedBox(width: 8),
                              _buildFilterTab('Done', 'done'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!snapshot.hasData)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: Color(0xFFA8D8EA)),
                          )
                        else if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No jobs in this filter yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildJobCard(filtered[index], index);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA8D8EA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
    final status = _uiStatus(job);
    Color statusColor;
    if (status == 'Open') {
      statusColor = const Color(0xFF2B7FFF);
    } else if (status == 'Filled') {
      statusColor = const Color(0xFFB366FF);
    } else if (status == 'Done') {
      statusColor = const Color(0xFF10B981);
    } else {
      statusColor = const Color(0xFF94A3B8);
    }

    final title = (job['title'] ?? 'Job').toString();

    final jobId = job['id']?.toString() ?? '';
    return GestureDetector(
      onTap: jobId.isEmpty
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobsDetailsScreen(jobId: jobId),
                ),
              ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _infoLine(job),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFA8D8EA),
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/clock.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFA8D8EA),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _dateTimeLine(job),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/dollar.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFA8D8EA),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'At hire',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _postedLine(job),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
