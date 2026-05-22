import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/custom_page_route.dart';
import 'quiz_screen.dart';

class CertificationDetailScreen extends StatefulWidget {
  const CertificationDetailScreen({super.key});

  @override
  State<CertificationDetailScreen> createState() =>
      _CertificationDetailScreenState();
}

class _CertificationDetailScreenState
    extends State<CertificationDetailScreen> {
  bool _isPlaying = false;

  static const List<_SectionData> _sections = [
    _SectionData(
      name: 'Section Name',
      lessons: [
        _LessonThumb(label: 'Already View', isCompleted: true,  imagePath: 'assets/section1-certificate.png'),
        _LessonThumb(label: 'Already View', isCompleted: true,  imagePath: 'assets/section1-certificate-1.png'),
      ],
    ),
    _SectionData(
      name: 'Section Name',
      lessons: [
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section2-certificate.png'),
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section2-certificate-1.png'),
      ],
    ),
    _SectionData(
      name: 'Section Name',
      lessons: [
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section3-certificate.png'),
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section3-certificate-1.png'),
      ],
    ),
    _SectionData(
      name: 'Section Name',
      lessons: [
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section4-certificate.png'),
        _LessonThumb(label: '', isCompleted: false, imagePath: 'assets/section4-certificate-1.png'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          // Dark overlay
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
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildCourseProgress(),
                        const SizedBox(height: 16),
                        _buildLessonCard(),
                        const SizedBox(height: 16),
                        _buildVideoPlayer(),
                        const SizedBox(height: 20),
                        ..._sections.map((s) => _buildSection(s)),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'CPR & First Aid',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Lesson 1 of 5',
            style: TextStyle(
              color: Color(0xFFC8F0FF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgress() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AA8D8EA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Progress',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '0/5 completed',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.05,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AA8D8EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x33D4B5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/openbook-icon.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFD4B5FF),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CPR Basics for Children',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '8 min',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CPR (Cardiopulmonary Resuscitation) is a life-saving technique. While this course provides an overview, you should complete hands-on CPR training. For children, use chest compressions at a rate of 100-120 per minute with a depth of about 2 inches.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          // Key Points box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1AD4B5FF),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                top: BorderSide(color: Color(0x4DD4B5FF), width: 1.09),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildKeyPoint('Call 911 immediately in emergencies'),
                _buildKeyPoint('Check for responsiveness before starting CPR'),
                _buildKeyPoint('Position child on firm, flat surface'),
                _buildKeyPoint(
                    'Perform 30 compressions followed by 2 rescue breaths'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/tick-icon.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFFB5FFD9),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD4B5FF),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          // Thumbnail image
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              'assets/main-certificate.png',
              fit: BoxFit.cover,
            ),
          ),
          // Play button overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: _isPlaying
                      ? const Icon(Icons.pause, color: Colors.white, size: 28)
                      : SvgPicture.asset(
                          'assets/play-icon.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Progress bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      value: 0.585,
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Text(
                        '0:52:35',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '  /  1:30:00',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_SectionData section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              section.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (section.lessons.any((l) => l.isCompleted))
              const Text(
                'Completed',
                style: TextStyle(
                  color: Color(0xFFC8F0FF),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: section.lessons.map((lesson) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: lesson == section.lessons.last ? 0 : 8,
                ),
                child: _buildLessonThumbnail(lesson),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLessonThumbnail(_LessonThumb lesson) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          // Thumbnail image
          SizedBox(
            height: 90,
            width: double.infinity,
            child: Image.asset(
              lesson.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          // Play icon
          Positioned(
            bottom: 8,
            left: 8,
            child: SvgPicture.asset(
              'assets/play-icon.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          // Completed label
          if (lesson.isCompleted)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Already View',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.0),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          CustomPageRoute(builder: (_) => const QuizScreen()),
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFC8F0FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Complete Course & Take Quiz',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Color(0xFF0F172A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _SectionData {
  final String name;
  final List<_LessonThumb> lessons;
  const _SectionData({required this.name, required this.lessons});
}

class _LessonThumb {
  final String label;
  final bool isCompleted;
  final String imagePath;
  const _LessonThumb({
    required this.label,
    required this.isCompleted,
    required this.imagePath,
  });
}
