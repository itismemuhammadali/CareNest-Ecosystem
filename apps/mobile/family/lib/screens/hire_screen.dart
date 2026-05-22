import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/bottom_nav_bar.dart';
import 'package:star_sitter_family/widgets/home_header.dart';
import 'package:star_sitter_family/widgets/search_bar.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'sitter_public_profile_screen.dart';

class HireScreen extends StatefulWidget {
  /// When true, used inside [HomeScreen] [IndexedStack] — no bottom bar.
  final bool embedded;
  const HireScreen({super.key, this.embedded = false});

  @override
  State<HireScreen> createState() => _HireScreenState();
}

class _HireScreenState extends State<HireScreen> {
  int _selectedIndex = 1;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _query = '';
  late Future<List<Map<String, dynamic>>> _sittersFuture;

  @override
  void initState() {
    super.initState();
    _sittersFuture = _loadSitters();
  }

  Future<List<Map<String, dynamic>>> _loadSitters() {
    return SittersRepository(Supabase.instance.client).listActiveSitters(limit: 80);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _ageFromDob(String? dobIso) {
    if (dobIso == null || dobIso.isEmpty) return null;
    final d = DateTime.tryParse(
      dobIso.length >= 10 ? dobIso.substring(0, 10) : dobIso,
    );
    if (d == null) return null;
    return (){final n=DateTime.now();return (n.year-d.year)-((n.month<d.month||(n.month==d.month&&n.day<d.day))?1:0);}();
  }

  Map<String, dynamic> _userMap(Map<String, dynamic> row) {
    final u = row['users'];
    if (u is Map) return Map<String, dynamic>.from(u as Map);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> rows) {
    var list = rows;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final u = _userMap(r);
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final bio = (r['bio'] ?? '').toString().toLowerCase();
        return name.contains(q) || bio.contains(q);
      }).toList();
    }
    if (_selectedFilter == 'Top Rated' || _selectedFilter == 'Most Experience') {
      list = List.from(list)
        ..sort((a, b) {
          final aMin = (a['total_minutes_worked'] as num?)?.toInt() ?? 0;
          final bMin = (b['total_minutes_worked'] as num?)?.toInt() ?? 0;
          return bMin.compareTo(aMin);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Column(
            children: [
              HomeHeader(
                onProfileTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                onNotificationTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFC8F0FF),
                  onRefresh: () async {
                    setState(() {
                      _sittersFuture = _loadSitters();
                    });
                    await _sittersFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Hire Babysitters',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Browse verified teen babysitters (active profiles)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomSearchBar(
                          hintText: 'Search babysitters',
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _query = value);
                          },
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', _selectedFilter == 'All'),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Top Rated',
                                _selectedFilter == 'Top Rated',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Most Experience',
                                _selectedFilter == 'Most Experience',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Available',
                                _selectedFilter == 'Available',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _sittersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Could not load sitters.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            }
                            final raw = snapshot.data ?? [];
                            final rows = _applyFilters(raw);
                            if (rows.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Text(
                                  raw.isEmpty
                                      ? 'No active sitters yet. Approve sitters in admin / Studio.'
                                      : 'No sitters match your search.',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (var i = 0; i < rows.length; i++) ...[
                                  _buildSitterCard(rows[i]),
                                  const SizedBox(height: 12),
                                ],
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC8F0FF)
                : Colors.white.withValues(alpha: 0.3),
          ),
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

  Widget _buildSitterCard(Map<String, dynamic> row) {
    final uid = row['user_id']?.toString() ?? '';
    final u = _userMap(row);
    final name = (u['full_name'] ?? 'Sitter').toString();
    final age = _ageFromDob(row['date_of_birth']?.toString());
    final ageLabel = age != null ? '$age years old' : '—';
    final bio = (row['bio'] ?? '').toString().trim();
    final subtitle =
        bio.isEmpty ? 'Verified teen sitter' : (bio.length > 80 ? '${bio.substring(0, 80)}…' : bio);

    return GestureDetector(
      onTap: () {
        if (uid.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SitterPublicProfileScreen(sitterUserId: uid),
          ),
        );
      },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _avatar(u['avatar_url']?.toString()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ageLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[700]?.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? url) {
    const size = 60.0;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/profilePicture.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'assets/profilePicture.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
