import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/custom_page_route.dart';
import 'quiz_screen.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  late final CoursesRepository _repo;
  Set<String> _completedIds = {};

  @override
  void initState() {
    super.initState();
    _repo = CoursesRepository(Supabase.instance.client);
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    try {
      final rows = await _repo.myCompletedCourseIds();
      if (mounted) {
        setState(() => _completedIds = rows.map((r) => r['course_id'].toString()).toSet());
      }
    } catch (_) {}
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 15, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Certifications',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete courses to earn certificates and boost your profile.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _repo.publishedCoursesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFA8D8EA)),
                        );
                      }
                      final courses = snapshot.data ?? [];
                      if (courses.isEmpty) {
                        return _emptyState();
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final course = courses[i];
                          final id = course['id'].toString();
                          final completed = _completedIds.contains(id);
                          return _CourseCard(
                            course: course,
                            completed: completed,
                            onStart: () {
                              Navigator.push(
                                context,
                                CustomPageRoute(
                                  builder: (_) => QuizScreen(
                                    courseId: id,
                                    courseName: course['name']?.toString() ?? 'Course Quiz',
                                  ),
                                ),
                              ).then((_) => _loadCompleted());
                            },
                          );
                        },
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0x991E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x4DA8D8EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/degree_cap_icon.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No published courses yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Check back soon — new training courses will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool completed;
  final VoidCallback onStart;

  const _CourseCard({required this.course, required this.completed, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final name = course['name']?.toString() ?? 'Course';
    final category = course['category']?.toString() ?? '';
    final description = course['description']?.toString() ?? '';
    final level = course['level']?.toString() ?? '';
    final durationHours = (course['duration_hours'] as num?)?.toStringAsFixed(1) ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? const Color(0x4DB5FFD9) : const Color(0x1AA8D8EA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x4DA8D8EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFA8D8EA), fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x33B5FFD9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB5FFD9), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55), height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (level.isNotEmpty)
                Text(level, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
              if (level.isNotEmpty && durationHours.isNotEmpty)
                Text('  ·  ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
              if (durationHours.isNotEmpty)
                Text('${durationHours}h', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed ? const Color(0x33B5FFD9) : const Color(0xFFC8F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                completed ? 'Retake Quiz' : 'Start Quiz',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: completed ? const Color(0xFFB5FFD9) : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          Builder(builder: (_) {
            final rawPaths = course['material_paths'];
            final paths = rawPaths is List
                ? rawPaths.whereType<String>().toList()
                : <String>[];
            if (paths.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () async {
                  final repo = CoursesRepository(Supabase.instance.client);
                  final url = await repo.getSignedUrl(paths.first);
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x4DA8D8EA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFA8D8EA)),
                      SizedBox(width: 6),
                      Text(
                        'View Materials',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA8D8EA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
