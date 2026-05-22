import 'dart:async';

import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/search_bar_widget.dart';
import '../widgets/home/certification_card.dart';
import '../widgets/home/wallet_card.dart';
import '../widgets/home/job_card.dart';
import 'browse_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'active_job_screen.dart';
import 'job_detail_screen.dart';
import '../utils/custom_page_route.dart';
import '../utils/open_job_row_ui.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentNavIndex;
  int _unreadMessageCount = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _unreadSub;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    _subscribeUnread();
  }

  void _subscribeUnread() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _unreadSub = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((rows) {
      final unread = rows.where((r) =>
          r['sender_id']?.toString() != uid && r['read_at'] == null).length;
      if (mounted) setState(() => _unreadMessageCount = unread);
    });
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
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

          // Main content — SafeArea only for bottom (nav bar)
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentNavIndex,
                    children: [
                      _HomeTab(onNavTap: _onNavTap),
                      BrowseTab(onNavTap: _onNavTap),
                      MessagesTab(onNavTap: _onNavTap),
                      ProfileTab(onNavTap: _onNavTap),
                    ],
                  ),
                ),
                BottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: _onNavTap,
                  unreadMessageCount: _unreadMessageCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final ValueChanged<int> onNavTap;
  const _HomeTab({required this.onNavTap});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Future<List<Map<String, dynamic>>> _appsFuture;
  late Future<List<Map<String, dynamic>>> _openJobsFuture;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    _appsFuture = uid == null
        ? Future.value(const <Map<String, dynamic>>[])
        : client
            .from('applications')
            .select('id, status, job_id, applied_at, jobs(title, location_address, date)')
            .eq('sitter_id', uid)
            .order('applied_at', ascending: false)
            .then(
              (res) => List<Map<String, dynamic>>.from(
                (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
              ),
            );
    _openJobsFuture = JobsRepository(client).openJobs();
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
          child: const HomeHeader(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SearchBarWidget(),
                const SizedBox(height: 14),
                const CertificationCard(),
                const SizedBox(height: 14),
                const WalletCard(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      CustomPageRoute(builder: (_) => const ActiveJobScreen()),
                    ),
                    child: const Text('Clock in / Clock out (active job)'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavTap(1),
                      child: const Text(
                        'View All',
                        style: TextStyle(fontSize: 13, color: Color(0xFFC8F0FF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _appsFuture,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text('${snap.error}', style: const TextStyle(color: Colors.white70));
                    }
                    final apps = snap.data ?? const <Map<String, dynamic>>[];
                    if (apps.isEmpty) {
                      return const Text(
                        'No applications yet — browse open jobs below.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      );
                    }
                    return Column(
                      children: apps.take(10).map((a) {
                        final st = a['status']?.toString() ?? '';
                        final job = a['jobs'] as Map<String, dynamic>?;
                        final title = job?['title']?.toString() ?? 'Application';
                        final addr = job?['location_address'];
                        String location = '';
                        if (addr is Map) {
                          location = (addr['formatted'] ?? addr['street'] ?? '').toString();
                        }
                        if (location.isEmpty) location = 'See Browse for details';
                        final jobDate = job?['date']?.toString() ??
                            a['applied_at']?.toString().substring(0, 10) ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: JobCard(
                            title: title,
                            family: '',
                            date: jobDate.length >= 10 ? jobDate.substring(0, 10) : jobDate,
                            time: st,
                            status: st,
                            location: location,
                            isAwaitingResponse: st == 'pending',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavTap(1),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC8F0FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _openJobsFuture,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text('${snap.error}', style: const TextStyle(color: Colors.white70));
                    }
                    final rows = snap.data ?? const <Map<String, dynamic>>[];
                    if (rows.isEmpty) {
                      return const Text(
                        'No open jobs.',
                        style: TextStyle(color: Colors.white70),
                      );
                    }
                    return Column(
                      children: rows.take(10).map((row) {
                        final ui = OpenJobRowUi.fromRow(row);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
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
                            child: JobCard(
                              title: ui.description.length > 40
                                  ? '${ui.description.substring(0, 40)}…'
                                  : ui.description,
                              family: ui.familyName,
                              date: ui.dateDisplay,
                              time: ui.hoursDisplay,
                              location: ui.location,
                              wage: ui.wageDisplay,
                              status: 'Open',
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
