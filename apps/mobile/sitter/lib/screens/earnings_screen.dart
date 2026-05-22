import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/custom_page_route.dart';
import 'job_history_screen.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

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
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(color: Colors.transparent),
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
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Earnings',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track your babysitting income',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: WalletRepository(Supabase.instance.client).ledgerStream(),
                    builder: (context, snap) {
                      final entries = snap.data ?? const [];
                      return _EarningsBody(entries: entries);
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
}

class _EarningsBody extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _EarningsBody({required this.entries});

  double get _total => entries.fold(0.0, (sum, e) {
        final amt = e['amount'];
        if (amt == null) return sum;
        return sum + (amt is num ? amt.toDouble() : double.tryParse(amt.toString()) ?? 0.0);
      });

  Map<String, double> get _byMonth {
    final map = <String, double>{};
    for (final e in entries) {
      final raw = e['created_at']?.toString();
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw);
      if (dt == null) continue;
      final key = DateFormat('MMMM yyyy').format(dt.toLocal());
      final amt = e['amount'];
      final val = amt is num ? amt.toDouble() : double.tryParse(amt?.toString() ?? '') ?? 0.0;
      map[key] = (map[key] ?? 0.0) + val;
    }
    return map;
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _byMonth;
    final monthKeys = monthly.keys.toList();
    final recent = entries.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0x991E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'Total Lifetime Earnings',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  _fmt(_total),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatBox(label: 'Entries', value: '${entries.length}')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: 'Months', value: '${monthly.length}')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: 'Avg/entry', value: entries.isEmpty ? '—' : _fmt(_total / entries.length))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Monthly Breakdown',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          monthKeys.isEmpty
              ? _card(
                  child: const Text(
                    'No earnings recorded yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                )
              : _card(
                  child: Column(
                    children: [
                      for (int i = 0; i < monthKeys.length; i++) ...[
                        _MonthRow(month: monthKeys[i], amount: _fmt(monthly[monthKeys[i]]!)),
                        if (i < monthKeys.length - 1)
                          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                      ],
                    ],
                  ),
                ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Earnings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, CustomPageRoute(builder: (_) => const JobHistoryScreen())),
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Text('No earnings yet.', style: TextStyle(color: Colors.white70, fontSize: 13))
          else
            for (final e in recent) ...[
              _EntryCard(entry: e),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Payments are processed weekly and transferred to your linked account. Set up your payment method in settings.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA8D8EA), width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFA8D8EA))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String month;
  final String amount;
  const _MonthRow({required this.month, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(month, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final amt = entry['amount'];
    final amtVal = amt is num ? amt.toDouble() : double.tryParse(amt?.toString() ?? '') ?? 0.0;
    final raw = entry['created_at']?.toString();
    final dt = raw != null ? DateTime.tryParse(raw) : null;
    final dateStr = dt != null ? DateFormat.yMMMd().format(dt.toLocal()) : '—';
    final desc = entry['description']?.toString() ?? entry['type']?.toString() ?? 'Earnings';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(
            '\$${amtVal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB5FFD9)),
          ),
        ],
      ),
    );
  }
}
