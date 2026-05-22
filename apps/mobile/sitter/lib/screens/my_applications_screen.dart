import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/custom_page_route.dart';
import '../utils/open_job_row_ui.dart';
import '../widgets/applications/application_card.dart';
import 'chat_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApplicationsRepository(Supabase.instance.client)
        .fetchMyApplicationsWithJobs();
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
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB30F172A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Applications',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track your job applications',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0x99A8D8EA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Could not load applications.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }
                      final rows = snapshot.data ?? [];
                      if (rows.isEmpty) {
                        return Center(
                          child: Text(
                            'No applications yet.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            for (final app in rows)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _cardForApplication(context, app),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardForApplication(
    BuildContext context,
    Map<String, dynamic> app,
  ) {
    final jobRaw = app['jobs'];
    if (jobRaw is! Map) {
      return ApplicationCard(
        familyName: 'Job',
        location: '—',
        date: '—',
        hours: '—',
        childrenCount: 0,
        wage: '—',
        totalWage: '—',
        description: 'Job details unavailable.',
        tags: [app['status']?.toString() ?? 'unknown'],
        onMessage: null,
      );
    }
    final job = Map<String, dynamic>.from(jobRaw);
    job['id'] = job['id'] ?? app['job_id'];
    final ui = OpenJobRowUi.fromRow(job);
    final status = app['status']?.toString() ?? '';
    final tags = <String>[...ui.tags, status];

    return ApplicationCard(
      familyName: ui.familyName,
      location: ui.location,
      date: ui.dateDisplay,
      hours: ui.hoursDisplay,
      childrenCount: ui.childrenCount,
      wage: ui.wageDisplay,
      totalWage: ui.totalWageDisplay,
      description: ui.description,
      tags: tags,
      onMessage: () => Navigator.push(
        context,
        CustomPageRoute(
          builder: (_) => ChatScreen(
            familyName: ui.familyName,
            subtitle: ui.detailDuration,
          ),
        ),
      ),
    );
  }
}
