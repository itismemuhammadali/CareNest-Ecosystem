import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/browse/browse_header.dart';
import '../widgets/browse/browse_filter_chips.dart';
import '../widgets/browse/browse_job_card.dart';
import '../widgets/home/search_bar_widget.dart';
import '../utils/custom_page_route.dart';
import '../utils/open_job_row_ui.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'job_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  int _currentNavIndex = 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB30F172A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _openJobsFuture,
                    builder: (context, snapshot) => BrowseHeader(
                      appliedCount: _appliedCount,
                      jobCount: snapshot.data?.length ?? 0,
                    ),
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
                            List<Map<String, dynamic>> rows = snapshot.data!;
                            if (_activeFilter == 'Today') {
                              final today = DateTime.now();
                              final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                              rows = rows.where((r) => (r['date']?.toString() ?? '').startsWith(todayStr)).toList();
                            } else if (_activeFilter == 'Weekend') {
                              rows = rows.where((r) {
                                final d = DateTime.tryParse(r['date']?.toString() ?? '');
                                return d != null && (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday);
                              }).toList();
                            }
                            if (rows.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'No open jobs right now.',
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
                BottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          builder: (_) => const MessagesScreen(),
                        ),
                      );
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    } else {
                      setState(() => _currentNavIndex = index);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
