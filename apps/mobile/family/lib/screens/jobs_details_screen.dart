import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sitter_chat_screen.dart';

/// Family job detail + live applicants + hire (BACKEND.md §17 `jobs_details_screen.dart`).
class JobsDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobsDetailsScreen({super.key, required this.jobId});

  @override
  State<JobsDetailsScreen> createState() => _JobsDetailsScreenState();
}

class _JobsDetailsScreenState extends State<JobsDetailsScreen> {
  Map<String, dynamic>? _job;
  Map<String, dynamic>? _hire;
  List<Map<String, dynamic>> _apps = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final client = Supabase.instance.client;
    final jobsRepo = JobsRepository(client);
    final appsRepo = ApplicationsRepository(client);
    try {
      final job = await jobsRepo.getJob(widget.jobId);
      final hire = await jobsRepo.hireForJob(widget.jobId);
      if (mounted) {
        setState(() {
          _job = job;
          _hire = hire;
          _loading = false;
          _error = job == null ? 'Job not found' : null;
        });
      }
      await _refreshApps();
      _sub = appsRepo.applicationsForJob(widget.jobId).listen((_) => _refreshApps());
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshApps() async {
    final apps = await ApplicationsRepository(Supabase.instance.client)
        .applicationsWithSitterUsers(widget.jobId);
    if (mounted) setState(() => _apps = apps);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _uiStatus(String? raw) {
    return switch (raw) {
      'open' => 'Open',
      'hired' => 'Filled',
      'active' => 'Live',
      'completed' => 'Done',
      'cancelled' => 'Cancelled',
      'draft' => 'Draft',
      _ => raw ?? '—',
    };
  }

  Future<void> _reportIssue() async {
    final reasonController = TextEditingController();
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
    try {
      await Supabase.instance.client.from('disputes').insert({
        'job_id': widget.jobId,
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

  Future<void> _submitHire(String applicationId) async {
    try {
      await ApplicationsRepository(Supabase.instance.client).hire(applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hired! Conversation is open.')),
      );
      final job = await JobsRepository(Supabase.instance.client).getJob(widget.jobId);
      final hire = await JobsRepository(Supabase.instance.client).hireForJob(widget.jobId);
      setState(() {
        _job = job;
        _hire = hire;
      });
      await _refreshApps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openChat() async {
    final repo = ConversationsRepository(Supabase.instance.client);
    final convId = await repo.conversationIdForJob(widget.jobId);
    if (!mounted) return;
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat opens after you hire a sitter.')),
      );
      return;
    }

    // Fetch sitter profile for the chat header
    final profile = await repo.fetchPartnerProfile(convId);
    if (!mounted) return;

    final name = profile?['full_name']?.toString() ?? 'Sitter chat';
    final avatar = profile?['avatar_url']?.toString();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SitterChatScreen(
          conversationId: convId,
          chatTitle: name,
          avatarUrl: avatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: Center(child: Text(_error ?? 'Missing job')),
      );
    }
    final j = _job!;
    final title = (j['title'] ?? 'Job').toString();
    final status = _uiStatus(j['status']?.toString());
    final dateStr = j['date']?.toString() ?? '';
    DateTime? day;
    if (dateStr.length >= 10) day = DateTime.tryParse(dateStr.substring(0, 10));
    final dateOut = day != null ? DateFormat.yMMMd().format(day) : dateStr;
    final start = j['start_time'] != null ? DateTime.tryParse(j['start_time'].toString()) : null;
    final end = j['end_time'] != null ? DateTime.tryParse(j['end_time'].toString()) : null;
    final timeOut = (start != null && end != null)
        ? '${DateFormat.jm('en_US').format(start.toLocal())} - ${DateFormat.jm('en_US').format(end.toLocal())}'
        : '—';
    final addr = j['location_address'];
    var loc = '—';
    if (addr is Map && addr['formatted'] != null) {
      loc = addr['formatted'].toString();
    }
    final noc = j['number_of_children'] ?? '—';

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const Header2(title: 'Job details'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2B7FFF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF51A2FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          _rowIcon(Icons.schedule, 'Date & time', '$dateOut · $timeOut'),
                          const SizedBox(height: 12),
                          _rowIconSvg('assets/location.svg', 'Location', loc),
                          const SizedBox(height: 12),
                          _rowIconSvg('assets/hire-icon.svg', 'Children', '$noc'),
                        ],
                      ),
                    ),
                    if (_hire != null) ...[
                      const SizedBox(height: 16),
                      _panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hired sitter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hourly rate \$${_hire!['hourly_rate']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _openChat,
                                child: const Text('Open chat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (j['status']?.toString() == 'completed') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _reportIssue,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          child: const Text('Report Issue', style: TextStyle(color: Color(0xFFEF4444))),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Applicants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_apps.isEmpty)
                      const Text(
                        'No applications yet.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ..._apps.map((a) {
                        final su = a['sitter_user'] as Map<String, dynamic>? ?? {};
                        final name = (su['full_name']?.toString().trim().isNotEmpty ?? false)
                            ? su['full_name'].toString()
                            : (su['email']?.toString() ?? 'Sitter');
                        final st = a['status']?.toString() ?? '';
                        final pending = st == 'pending';
                        final id = a['id']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $st',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                if ((a['cover_message'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    a['cover_message'].toString(),
                                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                                  ),
                                ],
                                if (pending && id.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _submitHire(id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFA8D8EA),
                                      ),
                                      child: const Text(
                                        'Hire',
                                        style: TextStyle(color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _rowIcon(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFA8D8EA), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowIconSvg(String asset, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          asset,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
