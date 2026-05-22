import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/transaction_model.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction tx;
  const TransactionDetailsScreen({super.key, required this.tx});

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
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Transaction Details',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.txnId,
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                  // ── Hero card ──
                  _HeroCard(tx: tx),
                  const SizedBox(height: 16),

                  // ── Transaction Information ──
                  _InfoCard(tx: tx),
                  const SizedBox(height: 16),
                  if (tx.ledgerMeta != null) _LedgerMetaCard(meta: tx.ledgerMeta!),
                  if (tx.ledgerMeta != null) const SizedBox(height: 16),

                  // ── Payment Breakdown ──
                  _BreakdownCard(tx: tx),
                  const SizedBox(height: 30),
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

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Transaction tx;
  const _HeroCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        children: [
          // Icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildIcon()),
          ),
          const SizedBox(height: 16),

          // Amount
          Text(
            tx.amount,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: tx.type == TxType.earning
                  ? const Color(0xFFB5FFD9)
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Label
          Text(
            _label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),

          // Status badge
          _StatusBadge(status: tx.status),
        ],
      ),
    );
  }

  String get _label {
    if (tx.ledgerMeta != null) {
      final raw = (tx.ledgerMeta!['raw_type'] ?? '').toString();
      if (raw == 'adjustment' || raw == 'refund') return 'Ledger adjustment';
    }
    switch (tx.type) {
      case TxType.earning:
        return 'Payment Received';
      case TxType.withdrawal:
        return 'Withdrawal';
      case TxType.purchase:
        return 'Course Purchase';
    }
  }

  Color get _iconBg {
    switch (tx.type) {
      case TxType.earning:
        return const Color(0x33B5FFD9);
      case TxType.withdrawal:
        return const Color(0x33FF6467);
      case TxType.purchase:
        return const Color(0x33D4B5FF);
    }
  }

  Widget _buildIcon() {
    switch (tx.type) {
      case TxType.earning:
        return SvgPicture.asset(
          'assets/receive-icon.svg',
          width: 26, height: 26,
          colorFilter: const ColorFilter.mode(Color(0xFFB5FFD9), BlendMode.srcIn),
        );
      case TxType.withdrawal:
        return SvgPicture.asset(
          'assets/withdraw-icon.svg',
          width: 26, height: 26,
          colorFilter: const ColorFilter.mode(Color(0xFFFF6467), BlendMode.srcIn),
        );
      case TxType.purchase:
        return SvgPicture.asset(
          'assets/card_icon.svg',
          width: 26, height: 26,
          colorFilter: const ColorFilter.mode(Color(0xFFD4B5FF), BlendMode.srcIn),
        );
    }
  }
}

// ── Transaction Information Card ──────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Transaction tx;
  const _InfoCard({required this.tx});

  // Split "Feb 18, 2026 • 7:30 PM" into date and time parts
  String get _datePart {
    final parts = tx.date.split(' • ');
    return parts.isNotEmpty ? parts[0] : tx.date;
  }

  String get _timePart {
    final parts = tx.date.split(' • ');
    return parts.length > 1 ? parts[1] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Date
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _datePart,
          ),
          _divider(),

          // Time
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: _timePart,
          ),

          // Earning-specific
          if (tx.type == TxType.earning) ...[
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFB5FFD9),
              iconSize: 10,
              label: 'Family',
              value: tx.title,
            ),
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFB5FFD9),
              iconSize: 10,
              label: 'Location',
              value: tx.location ?? '—',
            ),
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFB5FFD9),
              iconSize: 10,
              label: 'Children',
              value: tx.children ?? '—',
            ),
          ],

          // Withdrawal-specific
          if (tx.type == TxType.withdrawal) ...[
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFFF6467),
              iconSize: 10,
              label: 'Method',
              value: tx.method ?? 'Bank Account',
            ),
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFFF6467),
              iconSize: 10,
              label: 'Account',
              value: tx.account ?? '',
            ),
          ],

          // Purchase-specific (skip mock "course" row for ledger-backed purchase rows)
          if (tx.type == TxType.purchase && tx.ledgerMeta == null) ...[
            _divider(),
            _InfoRow(
              icon: Icons.circle,
              iconColor: const Color(0xFFD4B5FF),
              iconSize: 10,
              label: 'Course',
              value: tx.course ?? '',
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

/// Full timestamp + ledger fields from [Transaction.ledgerMeta].
class _LedgerMetaCard extends StatelessWidget {
  final Map<String, dynamic> meta;
  const _LedgerMetaCard({required this.meta});

  String _s(String key) => (meta[key] ?? '').toString().trim();

  String get _postedAt {
    final raw = _s('created_at');
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final mon = months[dt.month - 1];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$mon ${dt.day}, ${dt.year} • $h:$min $am';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ledger entry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Posted at',
            value: _postedAt,
          ),
          _divider(),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Raw ledger type',
            value: _s('raw_type').isEmpty ? '—' : _s('raw_type'),
          ),
          _divider(),
          _InfoRow(
            icon: Icons.link_outlined,
            label: 'Reference type',
            value: _s('reference_type').isEmpty ? '—' : _s('reference_type'),
          ),
          if (_s('reference_id').isNotEmpty) ...[
            _divider(),
            _InfoRow(
              icon: Icons.tag_outlined,
              label: 'Reference ID',
              value: _s('reference_id'),
            ),
          ],
          if (_s('balance_after').isNotEmpty) ...[
            _divider(),
            _InfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Balance after',
              value: '\$${_s('balance_after')}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    this.iconSize = 16,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Payment Breakdown Card ────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final Transaction tx;
  const _BreakdownCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx.ledgerMeta != null ? 'Ledger breakdown' : 'Payment Breakdown',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (tx.ledgerMeta != null) ...[
            _BreakdownRow(
              label: 'Ledger type',
              value: (tx.ledgerMeta!['raw_type'] ?? '—').toString(),
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'Reference type',
              value: (tx.ledgerMeta!['reference_type'] ?? '—').toString(),
            ),
            if ((tx.ledgerMeta!['reference_id'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _BreakdownRow(
                label: 'Reference ID',
                value: tx.ledgerMeta!['reference_id'].toString(),
              ),
            ],
            if ((tx.ledgerMeta!['balance_after'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _BreakdownRow(
                label: 'Balance after',
                value: '\$${tx.ledgerMeta!['balance_after']}',
              ),
            ],
          ] else ...[
            if (tx.type == TxType.earning) ...[
              _BreakdownRow(label: 'Job Date', value: tx.jobDate ?? ''),
              const SizedBox(height: 10),
              _BreakdownRow(label: 'Hours Worked', value: tx.hoursWorked ?? ''),
              const SizedBox(height: 10),
              _BreakdownRow(label: 'Hourly Rate', value: tx.hourlyRate ?? ''),
            ],
            if (tx.type == TxType.withdrawal) ...[
              _BreakdownRow(label: 'Method', value: tx.method ?? ''),
              const SizedBox(height: 10),
              _BreakdownRow(label: 'Account', value: tx.account ?? ''),
            ],
            if (tx.type == TxType.purchase) ...[
              _BreakdownRow(label: 'Course', value: tx.course ?? ''),
            ],
          ],

          // Divider + total
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                tx.amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tx.type == TxType.earning
                      ? const Color(0xFFB5FFD9)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPosted = status == 'posted';
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0x33D4B5FF)
            : const Color(0x1AB5FFD9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? const Color(0x4DD4B5FF)
              : const Color(0x4DB5FFD9),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? Icons.schedule : Icons.check_circle_outline,
            size: 13,
            color: isPending
                ? const Color(0xFFD4B5FF)
                : const Color(0xFFB5FFD9),
          ),
          const SizedBox(width: 5),
          Text(
            isPosted ? 'Posted' : (isPending ? 'Pending' : 'Completed'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPending
                  ? const Color(0xFFD4B5FF)
                  : const Color(0xFFB5FFD9),
            ),
          ),
        ],
      ),
    );
  }
}
