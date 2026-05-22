import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/custom_page_route.dart';
import 'chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  /// When set, Apply calls [ApplicationsRepository.createApplication].
  final String? jobId;
  final String familyName;
  final String location;
  final String wage;
  final String estimatedTotal;
  final String date;
  final String duration;
  final String children;
  final String description;
  final String requirements;

  const JobDetailScreen({
    super.key,
    this.jobId,
    required this.familyName,
    required this.location,
    required this.wage,
    required this.estimatedTotal,
    required this.date,
    required this.duration,
    required this.children,
    required this.description,
    required this.requirements,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _applied = false;
  bool _applying = false;
  final _coverController = TextEditingController();

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  Future<void> _reportIssue() async {
    final reasonController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report an Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe the issue…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0x221E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final jid = widget.jobId;
    if (jid == null || jid.isEmpty) return;
    try {
      await Supabase.instance.client.from('disputes').insert({
        'job_id': jid,
        'reported_by': Supabase.instance.client.auth.currentUser?.id,
        'reason': reasonController.text.trim(),
        'status': 'open',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue reported. Our team will review it.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _onApply() async {
    if (_applied || _applying) return;
    final id = widget.jobId;
    if (id == null || id.isEmpty) {
      setState(() => _applied = true);
      return;
    }

    // C8: Show cover message dialog and check certifications
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    // Fetch required certifications for this job
    final jobRow = await client
        .from('jobs')
        .select('required_certifications')
        .eq('id', id)
        .maybeSingle();
    final required = jobRow == null
        ? <String>[]
        : List<String>.from(jobRow['required_certifications'] as List? ?? []);

    if (required.isNotEmpty) {
      // Check sitter's approved certifications
      final certsRes = await client
          .from('certifications')
          .select('cert_type')
          .eq('sitter_id', uid)
          .eq('status', 'approved');
      final held = {
        for (final r in certsRes as List)
          (r as Map<String, dynamic>)['cert_type'].toString()
      };
      final missing = required.where((c) => !held.contains(c)).toList();
      if (missing.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing required certifications: ${missing.join(', ')}')),
        );
        return;
      }
    }

    // S5: Collect cover message before submitting
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apply for this job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _coverController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell the family why you\'re a great fit…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0x221E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8D8EA)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit Application', style: TextStyle(color: Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _applying = true);
    try {
      await ApplicationsRepository(client).createApplication(
        jobId: id,
        coverMessage: _coverController.text.trim().isEmpty ? null : _coverController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _applied = true;
          _applying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _applying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
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

          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
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
                  ),
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Family info card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.familyName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Color(0x99A8D8EA), size: 14),
                                  const SizedBox(width: 4),
                                  Text(widget.location,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0x99A8D8EA))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _statColumn('Hourly Rate', widget.wage),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(width: 16),
                                  _statColumn('Estimated Total', widget.estimatedTotal, valueColor: Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Job details card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Job Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _detailRowSvg('assets/calender-icon.svg', 'Date', widget.date),
                              const SizedBox(height: 12),
                              _detailRowSvg('assets/clock.svg', 'Duration', widget.duration),
                              const SizedBox(height: 12),
                              _detailRowSvg('assets/baby.svg', 'Children', widget.children),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0x99A8D8EA),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Requirements card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requirements',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.requirements,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0x99A8D8EA),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Applied confirmation card (visible after applying)
                        if (_applied)
                          _card(
                            color: const Color(0x1A4ADE80),
                            borderColor: const Color(0x334ADE80),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/tick-icon.svg',
                                      width: 20,
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Application Submitted!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'The family will review your application and may reach out via messages.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0x99A8D8EA),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_applied) const SizedBox(height: 12),

                        // Safety notice card
                        _card(
                          color: const Color(0x1AD4B5FF),
                          borderColor: const Color(0x4DD4B5FF),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset(
                                'assets/shield.svg',
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFD4B5FF),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'All families are verified and background checked. Communicate only through our secure messaging system.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFD4B5FF),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Message Family button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            CustomPageRoute(
                              builder: (_) => ChatScreen(
                                familyName: widget.familyName,
                              ),
                            ),
                          ),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFA8D8EA), width: 1),
                            ),
                            child: const Text(
                              'Message Family',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA8D8EA),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Apply / Applied button
                      Expanded(
                        child: GestureDetector(
                          onTap: (_applied || _applying) ? null : _onApply,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _applied
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFA8D8EA),
                              borderRadius: BorderRadius.circular(12),
                              border: _applied
                                  ? Border.all(
                                      color: const Color(0x33A8D8EA),
                                      width: 1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_applying) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Applying…',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ] else if (_applied) ...[
                                  SvgPicture.asset(
                                    'assets/tick-icon.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFA8D8EA),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Applied',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFA8D8EA),
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'Apply Now',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Report Issue button (for any job with a jobId — sitter can report after completion)
                if (widget.jobId != null && widget.jobId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _reportIssue,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        child: const Text('Report Issue', style: TextStyle(color: Color(0xFFEF4444))),
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

  Widget _card({
    required Widget child,
    Color color = const Color(0x991E293B),
    Color borderColor = const Color(0x1AA8D8EA),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.09),
      ),
      child: child,
    );
  }

  Widget _statColumn(String label, String value, {Color valueColor = const Color(0xFFB5FFD9)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            )),
      ],
    );
  }

  Widget _detailRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _detailRowSvg(String svgPath, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          svgPath,
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
      ],
    );
  }
}
