import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/custom_page_route.dart';
import 'quiz_result_screen.dart';
import 'quiz_pass_screen.dart';

class QuizScreen extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  const QuizScreen({super.key, this.courseId, this.courseName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _loading = true;

  static const List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question': 'What should you do FIRST in an emergency?',
      'options': ['Start CPR immediately', 'Call the parents', 'Call 911', 'Check for a pulse'],
      'correct': 2,
    },
    {
      'question': 'What is the correct compression rate for CPR on a child?',
      'options': ['60-80 per minute', '100-120 per minute', '140-160 per minute', '80-100 per minute'],
      'correct': 1,
    },
    {
      'question': 'How deep should chest compressions be for a child?',
      'options': ['About 1 inch', 'About 3 inches', 'About 2 inches', 'About 4 inches'],
      'correct': 2,
    },
  ];

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final courseId = widget.courseId;
      if (courseId != null && courseId.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('courses')
            .select('questions')
            .eq('id', courseId)
            .maybeSingle();
        if (res != null && res['questions'] is List) {
          final remote = (res['questions'] as List)
              .whereType<Map>()
              .map((q) => Map<String, dynamic>.from(q))
              .toList();
          if (remote.isNotEmpty) {
            if (mounted) setState(() { _questions = remote; _loading = false; });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _questions = _fallbackQuestions; _loading = false; });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final isCorrect = index == _questions[_currentQuestion]['correct'];
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
  }

  void _nextQuestion() {
    if (!_answered) return;
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      final scorePercent = ((_correctCount / _questions.length) * 100).round();
      final passed = scorePercent >= 80;
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          builder: (_) => passed
              ? QuizPassScreen(
                  courseId: widget.courseId,
                  courseName: widget.courseName,
                  score: scorePercent,
                  questionsAnswered: _questions.length,
                  correctAnswers: _correctCount,
                )
              : QuizResultScreen(
                  correct: _correctCount,
                  total: _questions.length,
                  courseId: widget.courseId,
                  courseName: widget.courseName,
                ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final q = _questions[_currentQuestion];
    final options = List<String>.from(q['options'] as List);
    final correctIndex = q['correct'] as int;
    final total = _questions.length;
    final progress = (_currentQuestion + 1) / total;

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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Back
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Back',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          widget.courseName?.isNotEmpty == true
                              ? widget.courseName!
                              : 'Course Quiz',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Question ${_currentQuestion + 1} of $total',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFA8D8EA)),
                        ),
                        const SizedBox(height: 16),

                        // Progress bar card
                        Container(
                          width: double.infinity,
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFA8D8EA)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Question card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q['question'] as String,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.4),
                              ),
                              const SizedBox(height: 20),

                              for (int i = 0; i < options.length; i++) ...[
                                _AnswerOption(
                                  label: options[i],
                                  state: _answered
                                      ? (i == correctIndex
                                          ? _OptionState.correct
                                          : i == _selectedAnswer
                                              ? _OptionState.wrong
                                              : _OptionState.normal)
                                      : (_selectedAnswer == i
                                          ? _OptionState.selected
                                          : _OptionState.normal),
                                  onTap: () => _selectAnswer(i),
                                ),
                                if (i < options.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom button
                Container(
                  padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 12),
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
                    onTap: _nextQuestion,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        color: _answered
                            ? const Color(0xFFC8F0FF)
                            : const Color(0xFFC8F0FF).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _currentQuestion < _questions.length - 1
                              ? 'Next Question'
                              : 'Finish Quiz',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _answered
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF0F172A)
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option state ──────────────────────────────────────────────────────────────

enum _OptionState { normal, selected, correct, wrong }

// ── Answer Option ─────────────────────────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color circleColor;
    Color circleBorder;
    Widget? circleChild;

    switch (state) {
      case _OptionState.correct:
        bgColor = const Color(0x33B5FFD9);
        borderColor = const Color(0xFFB5FFD9);
        textColor = Colors.white;
        circleColor = const Color(0xFFB5FFD9);
        circleBorder = const Color(0xFFB5FFD9);
        circleChild = SvgPicture.asset(
          'assets/tick-icon.svg',
          width: 12,
          height: 12,
          colorFilter:
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
        break;
      case _OptionState.wrong:
        bgColor = const Color(0x33FF6467);
        borderColor = const Color(0xFFFF6467);
        textColor = Colors.white;
        circleColor = const Color(0xFFFF6467);
        circleBorder = const Color(0xFFFF6467);
        circleChild = const Icon(Icons.close, color: Colors.white, size: 13);
        break;
      case _OptionState.selected:
        bgColor = const Color(0x33D4B5FF);
        borderColor = const Color(0xFFD4B5FF);
        textColor = Colors.white;
        circleColor = const Color(0xFFD4B5FF);
        circleBorder = const Color(0xFFD4B5FF);
        circleChild = SvgPicture.asset(
          'assets/tick-icon.svg',
          width: 12,
          height: 12,
          colorFilter:
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
        break;
      case _OptionState.normal:
        bgColor = Colors.white.withValues(alpha: 0.05);
        borderColor = Colors.white.withValues(alpha: 0.1);
        textColor = Colors.white.withValues(alpha: 0.7);
        circleColor = Colors.transparent;
        circleBorder = Colors.white.withValues(alpha: 0.3);
        circleChild = null;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(color: circleBorder, width: 1.5),
              ),
              child: circleChild != null ? Center(child: circleChild) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: state == _OptionState.normal
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
