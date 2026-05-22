import 'package:flutter/material.dart';
import '../utils/custom_page_route.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final int correct;
  final int total;
  final String? courseId;
  final String? courseName;

  const QuizResultScreen({
    super.key,
    required this.correct,
    required this.total,
    this.courseId,
    this.courseName,
  });

  int get _scorePercent => ((correct / total) * 100).round();
  bool get _passed => _scorePercent >= 80;
  int get _incorrect => total - correct;

  @override
  Widget build(BuildContext context) {
    final score = _scorePercent;
    final passed = _passed;

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Icon circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: passed
                          ? const Color(0x33B5FFD9)
                          : const Color(0x33FF6467),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        passed ? Icons.check_rounded : Icons.close_rounded,
                        color: passed
                            ? const Color(0xFFB5FFD9)
                            : const Color(0xFFFF6467),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    passed ? 'Congratulations!' : 'Keep Trying!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'You passed the quiz! Your certification is complete.'
                        : 'You need 80% to pass. Review the material and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0x991E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0x1AA8D8EA), width: 1),
                    ),
                    child: Column(
                      children: [
                        // Score percentage
                        Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Score',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              passed
                                  ? const Color(0xFFB5FFD9)
                                  : const Color(0xFFFF6467),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Correct / Incorrect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCol(
                              value: '$correct',
                              label: 'Correct',
                              color: Colors.white,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            _StatCol(
                              value: '$_incorrect',
                              label: 'Incorrect',
                              color: const Color(0xFFFF6467),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Retake Quiz button
                  _Button(
                    label: 'Retake Quiz',
                    filled: true,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      CustomPageRoute(
                        builder: (_) => QuizScreen(courseId: courseId, courseName: courseName),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Review Lessons button
                  _Button(
                    label: 'Review Lessons',
                    filled: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Go back to home
                  _Button(
                    label: 'Go back to home',
                    filled: false,
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      CustomPageRoute(
                          builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCol(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _Button(
      {required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFC8F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: const Color(0xFFA8D8EA), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: filled ? const Color(0xFF0F172A) : const Color(0xFFA8D8EA),
          ),
        ),
      ),
    );
  }
}
