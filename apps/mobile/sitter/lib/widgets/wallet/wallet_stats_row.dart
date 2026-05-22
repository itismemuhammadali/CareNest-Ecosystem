import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletStatsRow extends StatefulWidget {
  const WalletStatsRow({super.key});

  @override
  State<WalletStatsRow> createState() => _WalletStatsRowState();
}

class _WalletStatsRowState extends State<WalletStatsRow> {
  double _thisMonth = 0;
  double _totalEarned = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await WalletRepository(Supabase.instance.client).ledgerStream().first;
      final now = DateTime.now();
      double month = 0, total = 0;
      for (final e in entries) {
        final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
        if (amt > 0) {
          total += amt;
          final createdAt = e['created_at'] != null ? DateTime.tryParse(e['created_at'].toString()) : null;
          if (createdAt != null && createdAt.year == now.year && createdAt.month == now.month) {
            month += amt;
          }
        }
      }
      if (mounted) setState(() { _thisMonth = month; _totalEarned = total; });
    } catch (_) {}
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'This Month', value: _fmt(_thisMonth), icon: Icons.trending_up, iconColor: const Color(0xFFB5FFD9))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Total Earned', value: _fmt(_totalEarned), icon: Icons.attach_money, iconColor: const Color(0xFFD4B5FF))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0x99A8D8EA))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
