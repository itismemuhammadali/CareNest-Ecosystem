import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/hire_header.dart';
import 'hire_sitter_request_sent_screen.dart';

class HireSitterStep4Screen extends StatefulWidget {
  final String sitterName;
  final String hourlyRate;
  final String rating;
  final String jobCount;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int numberOfChildren;
  final String? estimatedTotal;
  final String? applicationId;
  final String? sitterId;
  final String? sitterAvatarUrl;

  const HireSitterStep4Screen({
    super.key,
    required this.sitterName,
    required this.hourlyRate,
    this.rating = '—',
    this.jobCount = '—',
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.numberOfChildren = 1,
    this.estimatedTotal,
    this.applicationId,
    this.sitterId,
    this.sitterAvatarUrl,
  });

  @override
  State<HireSitterStep4Screen> createState() => _HireSitterStep4ScreenState();
}

class _HireSitterStep4ScreenState extends State<HireSitterStep4Screen> {
  bool _submitting = false;

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(TimeOfDay t, BuildContext ctx) => t.format(ctx);

  DateTime _toDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _onSendHireRequest() async {
    setState(() => _submitting = true);
    try {
      final repo = ApplicationsRepository(Supabase.instance.client);
      final appId = widget.applicationId;
      if (appId != null && appId.isNotEmpty) {
        // Hired from job applicants list — application already exists
        await repo.hire(appId);
      } else {
        // Direct hire from browse — create job + application atomically
        final sid = widget.sitterId;
        final date = widget.selectedDate;
        final start = widget.startTime;
        final end = widget.endTime;
        if (sid == null || sid.isEmpty || date == null || start == null || end == null) {
          throw StateError('Missing sitter, date, or time — cannot complete hire.');
        }
        await repo.directHire(
          sitterId: sid,
          date: date,
          startTime: _toDateTime(date, start),
          endTime: _toDateTime(date, end),
          numberOfChildren: widget.numberOfChildren,
          title: 'Babysitting with ${widget.sitterName}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _submitting = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HireSitterRequestSentScreen(sitterName: widget.sitterName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.selectedDate != null ? _formatDate(widget.selectedDate!) : 'Not set';
    final timeStr = (widget.startTime != null && widget.endTime != null)
        ? '${_formatTime(widget.startTime!, context)} – ${_formatTime(widget.endTime!, context)}'
        : '—';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/screen-bg.jpg'), fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC0F172A), Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                HireHeader(title: 'Hire ${widget.sitterName}', currentStep: 4, totalSteps: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0x991E293B), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFF1E293B),
                                backgroundImage: (widget.sitterAvatarUrl != null && widget.sitterAvatarUrl!.isNotEmpty)
                                    ? NetworkImage(widget.sitterAvatarUrl!) as ImageProvider
                                    : null,
                                child: (widget.sitterAvatarUrl == null || widget.sitterAvatarUrl!.isEmpty)
                                    ? const Icon(Icons.person, color: Colors.white38, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.sitterName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                                      const SizedBox(width: 4),
                                      Text('${widget.rating} • ${widget.jobCount} jobs', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.attach_money, color: Color(0xFFC8F0FF), size: 14),
                                      Text(widget.hourlyRate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC8F0FF))),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text('Review your request',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Make sure everything looks good before sending',
                            style: TextStyle(fontSize: 16, color: Colors.white60)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summaryItem(
                                iconPath: 'assets/clock.svg',
                                label: 'Date & Time',
                                value: dateStr,
                                subValue: timeStr,
                              ),
                              Divider(color: Colors.white.withValues(alpha: 0.1), height: 28),
                              _summaryItem(
                                iconPath: 'assets/hire-icon.svg',
                                label: 'Number of Children',
                                value: '${widget.numberOfChildren}',
                              ),
                              Divider(color: Colors.white.withValues(alpha: 0.1), height: 28),
                              _summaryItem(
                                iconPath: 'assets/dollar.svg',
                                label: 'Rate & Estimated Total',
                                value: widget.hourlyRate,
                                highlightValue: widget.estimatedTotal != null ? '~${widget.estimatedTotal} total' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2B1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1A5C35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, color: Color(0xFF4ADE80), size: 16),
                                  SizedBox(width: 6),
                                  Text('Ready to send!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.sitterName} will be notified and can accept or decline this request. You\'ll receive a notification either way.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Text(
                            '🔒 No payment required now. You\'ll only be charged after the job is completed.',
                            style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.4),
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
      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 53,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onSendHireRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                      : const Text('Send Hire Request', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem({
    required String iconPath,
    required String label,
    required String value,
    String? subValue,
    String? highlightValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset(iconPath, width: 18, height: 18,
              colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(subValue, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
              if (highlightValue != null) ...[
                const SizedBox(height: 2),
                Text(highlightValue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFA8D8EA))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
