import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/primary_button.dart';
import '../widgets/hire_header.dart';
import '../services/job_post_session.dart';
import 'post_new_job_step4_screen.dart';

class PostNewJobStep3Screen extends StatefulWidget {
  const PostNewJobStep3Screen({super.key});

  @override
  State<PostNewJobStep3Screen> createState() => _PostNewJobStep3ScreenState();
}

class _PostNewJobStep3ScreenState extends State<PostNewJobStep3Screen> {
  double? _minRate;
  double? _maxRate;
  bool _loading = true;
  List<Map<String, dynamic>> _children = [];
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _selectedIds = Set.from(JobPostSession.selectedChildIds);
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('age_wage_tiers').select('hourly_rate').order('hourly_rate', ascending: true),
        ProfileRepository(client).listFamilyChildren(),
      ]);
      final tiers = List<Map<String, dynamic>>.from(results[0] as List);
      final kids = List<Map<String, dynamic>>.from(results[1] as List);
      if (!mounted) return;
      setState(() {
        if (tiers.isNotEmpty) {
          final rates = tiers.map((e) => double.tryParse(e['hourly_rate'].toString()) ?? 0.0).toList();
          _minRate = rates.first;
          _maxRate = rates.last;
        }
        _children = kids;
        if (_selectedIds.isEmpty) {
          _selectedIds = kids.map((c) => c['id'].toString()).toSet();
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _rateDisplay {
    if (_minRate == null) return 'TBD';
    if (_maxRate != null && _maxRate != _minRate) {
      return '\$${_minRate!.toStringAsFixed(2)}–\$${_maxRate!.toStringAsFixed(2)}/hr';
    }
    return '\$${_minRate!.toStringAsFixed(2)}/hr';
  }

  String get _durationDisplay {
    final start = JobPostSession.combineDateAndTime(DateTime.now(), JobPostSession.startTimeStr);
    final end = JobPostSession.combineDateAndTime(DateTime.now(), JobPostSession.endTimeStr);
    if (start == null || end == null || !end.isAfter(start)) return '—';
    final mins = end.difference(start).inMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '$h hour${h != 1 ? 's' : ''}';
    return '$h hr $m min';
  }

  String get _estimatedTotal {
    if (_minRate == null) return 'TBD';
    final start = JobPostSession.combineDateAndTime(DateTime.now(), JobPostSession.startTimeStr);
    final end = JobPostSession.combineDateAndTime(DateTime.now(), JobPostSession.endTimeStr);
    if (start == null || end == null || !end.isAfter(start)) return 'TBD';
    final hours = end.difference(start).inMinutes / 60.0;
    final low = (_minRate! * hours);
    if (_maxRate != null && _maxRate != _minRate) {
      final high = (_maxRate! * hours);
      return '\$${low.toStringAsFixed(0)}–\$${high.toStringAsFixed(0)}';
    }
    return '\$${low.toStringAsFixed(0)}';
  }

  void _onContinue() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one child for this job.')),
      );
      return;
    }
    JobPostSession.selectedChildIds = _selectedIds.toList();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostNewJobStep4Screen()));
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
                colors: [Color(0xB30F172A), Color(0xFF0F172A)],
              ),
            ),
          ),
          Column(
            children: [
              const HireHeader(title: 'Post New Job', currentStep: 3, totalSteps: 4),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Wage Preview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0x991E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Hourly Rate',
                                          style: TextStyle(fontSize: 14, color: Colors.white70)),
                                      Text(_rateDisplay,
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Estimated Duration',
                                          style: TextStyle(fontSize: 14, color: Colors.white70)),
                                      Text(_durationDisplay,
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Estimated Total',
                                          style: TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(_estimatedTotal,
                                          style: const TextStyle(
                                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x991E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: const Text(
                                'Wage is automatically calculated based on babysitter\'s age and admin approved rates. Final amount may vary based on actual time worked.',
                                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Child selection
                            const Text(
                              'Select Children',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            if (_children.isEmpty)
                              const Text(
                                'No children in your profile. Add a child in your account settings.',
                                style: TextStyle(fontSize: 13, color: Colors.white70),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x991E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  children: _children.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final child = entry.value;
                                    final id = child['id'].toString();
                                    final name = child['name']?.toString() ?? 'Child ${idx + 1}';
                                    final age = child['age_years']?.toString() ?? '—';
                                    final checked = _selectedIds.contains(id);
                                    return InkWell(
                                      onTap: () => setState(() {
                                        if (checked) {
                                          _selectedIds.remove(id);
                                        } else {
                                          _selectedIds.add(id);
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: checked,
                                              onChanged: (_) => setState(() {
                                                if (checked) {
                                                  _selectedIds.remove(id);
                                                } else {
                                                  _selectedIds.add(id);
                                                }
                                              }),
                                              activeColor: const Color(0xFFA8D8EA),
                                              checkColor: const Color(0xFF0F172A),
                                              side: const BorderSide(color: Colors.white38),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$name · $age yr${age == '1' ? '' : 's'}',
                                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 20),
                            PrimaryButton(label: 'Continue', onPressed: _onContinue),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
