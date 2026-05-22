import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/custom_page_route.dart';
import '../utils/open_job_row_ui.dart';
import '../widgets/browse/browse_header.dart';
import '../widgets/browse/browse_filter_chips.dart';
import '../widgets/browse/browse_job_card.dart';
import '../widgets/home/search_bar_widget.dart';
import 'job_detail_screen.dart';

class BrowseTab extends StatefulWidget {
  final ValueChanged<int> onNavTap;
  const BrowseTab({super.key, required this.onNavTap});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  late Future<List<Map<String, dynamic>>> _openJobsFuture;
  int _appliedCount = 0;
  String _activeFilter = 'All Jobs';

  @override
  void initState() {
    super.initState();
    _openJobsFuture = JobsRepository(Supabase.instance.client).openJobs();
    JobsRepository(Supabase.instance.client)
        .countMySitterApplications()
        .then((count) {
      if (mounted) setState(() => _appliedCount = count);
    });
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> rows) {
    if (_activeFilter == 'All Jobs') return rows;
    if (_activeFilter == 'Today') {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      return rows.where((r) {
        final d = r['date']?.toString() ?? '';
        return d.startsWith(todayStr);
      }).toList();
    }
    if (_activeFilter == 'Weekend') {
      return rows.where((r) {
        final d = DateTime.tryParse(r['date']?.toString() ?? '');
        if (d == null) return false;
        return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
      }).toList();
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _openJobsFuture,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return BrowseHeader(appliedCount: _appliedCount, jobCount: count);
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SearchBarWidget(),
                const SizedBox(height: 12),
                BrowseFilterChips(
                  activeFilter: _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _openJobsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Could not load jobs: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final rows = _applyFilter(snapshot.data!);
                    if (rows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No open jobs right now. Check back soon.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      );
                    }
                    return Column(
                      children: rows.map((row) {
                        final ui = OpenJobRowUi.fromRow(row);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BrowseJobCard(
                            familyName: ui.familyName,
                            location: ui.location,
                            date: ui.dateDisplay,
                            hours: ui.hoursDisplay,
                            childrenCount: ui.childrenCount,
                            wage: ui.wageDisplay,
                            totalWage: ui.totalWageDisplay,
                            description: ui.description,
                            tags: ui.tags,
                            onApplyNow: () => Navigator.push(
                              context,
                              CustomPageRoute(
                                builder: (_) => JobDetailScreen(
                                  jobId: ui.jobId.isEmpty ? null : ui.jobId,
                                  familyName: ui.familyName,
                                  location: ui.location,
                                  wage: ui.wageDisplay,
                                  estimatedTotal: ui.totalWageDisplay,
                                  date: ui.detailDate,
                                  duration: ui.detailDuration,
                                  children: ui.detailChildrenLabel,
                                  description: ui.description,
                                  requirements: '',
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
