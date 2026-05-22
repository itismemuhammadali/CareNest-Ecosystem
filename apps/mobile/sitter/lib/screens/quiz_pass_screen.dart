import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/custom_page_route.dart';
import 'home_screen.dart';

class QuizPassScreen extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  final num? score;
  final int? questionsAnswered;
  final int? correctAnswers;
  const QuizPassScreen({
    super.key,
    this.courseId,
    this.courseName,
    this.score,
    this.questionsAnswered,
    this.correctAnswers,
  });

  @override
  State<QuizPassScreen> createState() => _QuizPassScreenState();
}

class _QuizPassScreenState extends State<QuizPassScreen> {
  bool _submitted = false;
  String _sitterName = 'Babysitter';
  final String _completionDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _submitCert();
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final user = await ProfileRepository(Supabase.instance.client).currentUserRow();
      final name = user?['full_name']?.toString() ?? '';
      if (mounted && name.isNotEmpty) setState(() => _sitterName = name.trim().split(' ').first);
    } catch (_) {}
  }

  Future<void> _submitCert() async {
    final cid = widget.courseId;
    if (cid == null || cid.isEmpty || _submitted) return;
    _submitted = true;
    try {
      await ProfileRepository(Supabase.instance.client).submitCertification(
        courseId: cid,
        score: widget.score,
        questionsAnswered: widget.questionsAnswered,
        correctAnswers: widget.correctAnswers,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final courseName = widget.courseName?.isNotEmpty == true ? widget.courseName! : 'Babysitting Course';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/screen-bg.jpg'), fit: BoxFit.cover),
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
                        const Text('Certificate of Completion',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        const Text('Congratulations on completing the course!',
                            style: TextStyle(fontSize: 13, color: Color(0xFFA8D8EA))),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Color(0x40000000), offset: Offset(0, 25), blurRadius: 50, spreadRadius: -12),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFDC700), Color(0xFF7C6100)],
                                  ),
                                  border: Border.all(color: const Color(0xFFFAF173), width: 3.33),
                                ),
                                child: Center(
                                  child: SvgPicture.asset('assets/medal-icon.svg', width: 36, height: 36,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text('Certificate of\nCompletion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), height: 1.3)),
                              const SizedBox(height: 16),
                              Container(width: 60, height: 1, color: const Color(0xFFCCCCCC)),
                              const SizedBox(height: 16),
                              const Text('This certifies that', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                              const SizedBox(height: 8),
                              Text(_sitterName,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 8),
                              const Text('has successfully completed', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                              const SizedBox(height: 8),
                              Text(courseName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 6),
                              Text('on $_completionDate', style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                              const SizedBox(height: 24),
                              Container(height: 1, color: const Color(0xFFE0E0E0)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Course Instructor', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                                      SizedBox(height: 4),
                                      Text('Teen Babysitter\nAcademy',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), height: 1.4)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Date', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                                      const SizedBox(height: 4),
                                      Text(_completionDate,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Your certificate will be emailed once your submission is reviewed by an admin.'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity, height: 54,
                            decoration: BoxDecoration(color: const Color(0xFFC8F0FF), borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/download_icon.svg', width: 18, height: 18,
                                    colorFilter: const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
                                const SizedBox(width: 8),
                                const Text('Download Certificate',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("What's Next?",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text('Continue building your skills with more courses, or start applying to babysitting jobs!',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5), height: 1.4)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        height: 44, alignment: Alignment.center,
                                        decoration: BoxDecoration(color: const Color(0xFFB5FFD9), borderRadius: BorderRadius.circular(10)),
                                        child: const Text('More Courses',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                                        CustomPageRoute(builder: (_) => const HomeScreen()),
                                        (route) => false,
                                      ),
                                      child: Container(
                                        height: 44, alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFA8D8EA), width: 1),
                                        ),
                                        child: const Text('Browse Jobs',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA8D8EA))),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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
