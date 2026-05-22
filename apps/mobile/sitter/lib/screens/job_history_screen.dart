import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/hire_history_ui.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  String _activeFilter = 'All Jobs';
  List<String> _filters = const ['All Jobs'];
  List<Map<String, dynamic>> _allCards = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hires = await JobsRepository(Supabase.instance.client)
          .sitterHireHistoryWithJobs();
      if (!mounted) return;
      final cards =
          hires.map((h) => HireHistoryUi.jobCardFromHire(h)).toList();
      final seen = <String>{};
      final months = <String>[];
      for (final c in cards) {
        final m = (c['month'] as String?) ?? '';
        if (m.isNotEmpty && seen.add(m)) {
          months.add(m);
        }
      }
      setState(() {
        _allCards = cards;
        _filters = ['All Jobs', ...months];
        _loading = false;
        _error = null;
        if (!_filters.contains(_activeFilter)) {
          _activeFilter = 'All Jobs';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == 'All Jobs') return _allCards;
    return _allCards.where((j) => j['month'] == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _filtered;
    final totals = HireHistoryUi.totals(jobs);
    final earnedStr = '\$${totals.totalEarned.toStringAsFixed(2)}';
    final hoursStr = totals.totalHours.toStringAsFixed(1);

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
                // ── Pinned header ──
                Container(
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
                            Icon(Icons.arrow_back,
                                color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Job History',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loading
                            ? 'Loading…'
                            : '${_allCards.length} hire${_allCards.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ──
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Could not load job history.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryCard(
                                          label: 'Total Earned (filtered)',
                                          value: earnedStr,
                                          valueColor:
                                              const Color(0xFFB5FFD9),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _SummaryCard(
                                          label: 'Total Hours (filtered)',
                                          value: hoursStr,
                                          valueColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (final f in _filters) ...[
                                          _FilterChip(
                                            label: f,
                                            active: _activeFilter == f,
                                            onTap: () => setState(
                                                () => _activeFilter = f),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (jobs.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 40),
                                        child: Text(
                                          'No jobs found',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4),
                                              fontSize: 14),
                                        ),
                                      ),
                                    )
                                  else
                                    for (final job in jobs) ...[
                                      _JobCard(job: job),
                                      const SizedBox(height: 12),
                                    ],
                                  const SizedBox(height: 24),
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

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFA8D8EA) : const Color(0x1AA8D8EA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFA8D8EA)
                : const Color(0x4DA8D8EA),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF0F172A) : const Color(0xFFA8D8EA),
          ),
        ),
      ),
    );
  }
}

// ── Job Card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job['family'] as String,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              _StatusBadge(status: job['status'] as String),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job['date'] as String,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _StatCol(label: 'Hours', value: job['hours'] as String),
              const SizedBox(width: 32),
              _StatCol(label: 'Rate', value: job['rate'] as String),
              const SizedBox(width: 32),
              _StatCol(label: 'Earned', value: job['earned'] as String),
            ],
          ),
          const SizedBox(height: 14),

          // Divider
          Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
              thickness: 1),
          const SizedBox(height: 12),

          // View Details
          Row(
            children: const [
              Text(
                'View Details',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA8D8EA)),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: Color(0xFFA8D8EA), size: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AB5FFD9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4DB5FFD9), width: 1),
      ),
      child: Text(
        status,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFFB5FFD9)),
      ),
    );
  }
}
