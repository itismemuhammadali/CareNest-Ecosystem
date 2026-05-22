import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/header2.dart';

/// Family app: read-only sitter profile from Supabase (`SittersRepository.getSitterPublicBundle`).
class SitterPublicProfileScreen extends StatefulWidget {
  final String sitterUserId;

  const SitterPublicProfileScreen({super.key, required this.sitterUserId});

  @override
  State<SitterPublicProfileScreen> createState() =>
      _SitterPublicProfileScreenState();
}

class _SitterPublicProfileScreenState extends State<SitterPublicProfileScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = SittersRepository(Supabase.instance.client)
        .getSitterPublicBundle(widget.sitterUserId);
  }

  String _ageLabel(String? dobIso) {
    if (dobIso == null || dobIso.isEmpty) return '—';
    final d = DateTime.tryParse(dobIso.length >= 10 ? dobIso.substring(0, 10) : dobIso);
    if (d == null) return '—';
    final years = (){final n=DateTime.now();return (n.year-d.year)-((n.month<d.month||(n.month==d.month&&n.day<d.day))?1:0);}();
    return '$years years old';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/screen-bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
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
          Column(
            children: [
              const Header2(title: 'Sitter profile'),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError || snap.data == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Sitter not found or not available for hire.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      );
                    }
                    final row = snap.data!;
                    final users = row['users'];
                    final u = users is Map
                        ? Map<String, dynamic>.from(users as Map)
                        : <String, dynamic>{};
                    final name = (u['full_name'] ?? 'Sitter').toString();
                    final avatar = u['avatar_url']?.toString();
                    final bio = (row['bio'] ?? '').toString().trim();
                    final dob = row['date_of_birth']?.toString();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: avatar != null && avatar.isNotEmpty
                                    ? Image.network(
                                        avatar,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/profilePicture.png',
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/profilePicture.png',
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _ageLabel(dob),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33166534),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Verified sitter',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4ADE80),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio.isEmpty
                                ? 'This sitter has not added a bio yet.'
                                : bio,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Hiring happens from your job post: post a shift, review applications, then hire.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
