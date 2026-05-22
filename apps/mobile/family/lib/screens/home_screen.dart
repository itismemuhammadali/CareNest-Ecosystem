import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/bottom_nav_bar.dart';
import 'package:star_sitter_family/widgets/search_bar.dart' as search_bar;
import 'package:star_sitter_family/widgets/home_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifications_screen.dart';
import 'post_new_job_step1_screen.dart';
import 'profile_screen.dart';
import 'hire_screen.dart';
import 'messages_screen.dart';
import 'jobs_details_screen.dart';
import 'my_posted_jobs_screen.dart';
import 'sitter_public_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _unreadMessageCount = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _unreadSub;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark gradient overlay
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
          // Content
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      Column(
                        children: [
                HomeHeader(
                  onProfileTap: () => setState(() => _selectedIndex = 3),
                  onNotificationTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Search bar
                        search_bar.CustomSearchBar(
                          hintText: 'Search Babysitters',
                        ),
                        const SizedBox(height: 20),
                        // Post New Job card
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PostNewJobStep1Screen()),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0x991E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.09,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/newJob.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Post New Job',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Find the perfect babysitter for your family',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Your Jobs section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Jobs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyPostedJobsScreen()),
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC8F0FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _yourJobsSection(context),
                        const SizedBox(height: 16),
                        // Background check banner (D2)
                        _BgCheckBanner(),
                        const SizedBox(height: 28),
                        // Highly Recommended section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Highly Recommended',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC8F0FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Live sitters from DB (D1)
                        _RecommendedSitters(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                        ],
                      ),
                      const HireScreen(embedded: true),
                      const MessagesScreen(embedded: true),
                      const ProfileScreen(embedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
        },
        unreadMessageCount: _unreadMessageCount,
      ),
    );
  }

  Widget _yourJobsSection(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: JobsRepository(Supabase.instance.client).myFamilyJobs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Jobs: ${snapshot.error}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return const Text(
            'No jobs yet — post one from above.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          );
        }
        return Column(
          children: rows.take(5).map((j) {
            final id = j['id']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: id.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobsDetailsScreen(jobId: id),
                          ),
                        ),
                child: _buildJobCardFromRow(j),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildJobCardFromRow(Map<String, dynamic> j) {
    final title = (j['title'] ?? 'Job').toString();
    final raw = j['status']?.toString() ?? '';
    final uiStatus = switch (raw) {
      'open' => 'Open',
      'hired' => 'Filled',
      'active' => 'Filled',
      'completed' => 'Done',
      'cancelled' => 'Cancelled',
      'draft' => 'Draft',
      _ => raw.isEmpty ? '—' : raw,
    };
    final dateStr = j['date']?.toString() ?? '';
    DateTime? day;
    if (dateStr.length >= 10) {
      day = DateTime.tryParse(dateStr.substring(0, 10));
    }
    final dateOut = day != null ? DateFormat.yMMMd().format(day) : dateStr;
    final start = j['start_time'] != null ? DateTime.tryParse(j['start_time'].toString()) : null;
    final end = j['end_time'] != null ? DateTime.tryParse(j['end_time'].toString()) : null;
    final timeOut = (start != null && end != null)
        ? '${DateFormat.jm('en_US').format(start.toLocal())} - ${DateFormat.jm('en_US').format(end.toLocal())}'
        : '—';
    final applicants = raw == 'open' ? 'Open for applications' : 'Status: $uiStatus';
    return _buildJobCard(
      title: title,
      status: uiStatus,
      date: dateOut,
      time: timeOut,
      applicants: applicants,
    );
  }

  Widget _buildJobCard({
    required String title,
    required String status,
    required String date,
    required String time,
    required String applicants,
    String? sitter,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.09,
        ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Open'
                      ? const Color(0xFF2B7FFF).withValues(alpha: 0.2)
                      : Colors.grey[700]?.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'Open' ? const Color(0xFF51A2FF) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sitter ?? status,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SvgPicture.asset(
                'assets/callender.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Colors.white54,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/clockGray.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Colors.white54,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFA8D8EA).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA8D8EA),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  applicants,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA8D8EA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBabysitterCard({
    required String name,
    required String jobs,
    required String age,
    required String rating,
    required String availability,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.09,
          ),
        ),
        child: Row(
          children: [
            // Square image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Jobs and Age
                  Text(
                    '$jobs • $age',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Availability badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05DF72).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF05DF72),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          availability,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF05DF72),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// D2 — streams bg_check_status and shows banner when not approved
class _BgCheckBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: ProfileRepository(Supabase.instance.client).watchFamilyProfileRow(),
      builder: (context, snap) {
        final status = snap.data?['bg_check_status']?.toString() ?? '';
        if (status == 'approved') return const SizedBox.shrink();
        final msg = status == 'pending'
            ? 'Your background check is under review.'
            : 'Complete your background check to post jobs.';
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA500).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFA500).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA500), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFD580)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// D1 — loads top 3 active sitters from DB
class _RecommendedSitters extends StatelessWidget {
  int? _ageFromDob(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final d = DateTime.tryParse(dob.length >= 10 ? dob.substring(0, 10) : dob);
    if (d == null) return null;
    return (){final n=DateTime.now();return (n.year-d.year)-((n.month<d.month||(n.month==d.month&&n.day<d.day))?1:0);}();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SittersRepository(Supabase.instance.client).listActiveSitters(limit: 3),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return const Text(
            'No active sitters yet.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          );
        }
        return Column(
          children: rows.map((row) {
            final u = row['users'];
            final userMap = u is Map ? Map<String, dynamic>.from(u as Map) : <String, dynamic>{};
            final name = (userMap['full_name'] ?? 'Sitter').toString();
            final uid = (row['user_id'] ?? '').toString();
            final age = _ageFromDob(row['date_of_birth']?.toString());
            final ageLabel = age != null ? '$age years old' : '—';
            final avatarUrl = userMap['avatar_url']?.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: uid.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SitterPublicProfileScreen(sitterUserId: uid),
                          ),
                        ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x991E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.09,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(avatarUrl, width: 60, height: 60, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset('assets/profilePicture.png', width: 60, height: 60, fit: BoxFit.cover))
                            : Image.asset('assets/profilePicture.png', width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ageLabel,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF05DF72).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(color: Color(0xFF05DF72), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Active',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF05DF72), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}