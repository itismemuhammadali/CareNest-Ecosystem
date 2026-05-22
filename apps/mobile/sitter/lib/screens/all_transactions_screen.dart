import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../utils/custom_page_route.dart';
import 'transaction_details_screen.dart';

enum TxFilter { all, payments, withdrawals, fund }

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  TxFilter _activeFilter = TxFilter.all;

  List<Transaction> _applyFilter(List<Transaction> txs) {
    switch (_activeFilter) {
      case TxFilter.all:
        return txs;
      case TxFilter.payments:
        return txs.where((t) => t.type == TxType.earning).toList();
      case TxFilter.withdrawals:
        return txs.where((t) => t.type == TxType.withdrawal).toList();
      case TxFilter.fund:
        return txs.where((t) => t.type == TxType.purchase).toList();
    }
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        'All Transactions',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Complete transaction history',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 16),
                      _FilterBar(
                        active: _activeFilter,
                        onChanged: (f) => setState(() => _activeFilter = f),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: WalletRepository(Supabase.instance.client)
                        .ledgerStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Could not load transactions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      final rows = List<Map<String, dynamic>>.from(
                        snapshot.data ?? const [],
                      );
                      rows.sort((a, b) {
                        final ca = a['created_at']?.toString() ?? '';
                        final cb = b['created_at']?.toString() ?? '';
                        return cb.compareTo(ca);
                      });
                      final txs = rows
                          .map(
                            (r) => Transaction.fromLedgerRow(
                              Map<String, dynamic>.from(r),
                            ),
                          )
                          .toList();
                      final transactions = _applyFilter(txs);
                      if (transactions.isEmpty) {
                        return Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            CustomPageRoute(
                              builder: (_) => TransactionDetailsScreen(
                                tx: transactions[i],
                              ),
                            ),
                          ),
                          child: _TransactionCard(tx: transactions[i]),
                        ),
                      );
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

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TxFilter active;
  final ValueChanged<TxFilter> onChanged;

  const _FilterBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33A8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_outlined,
                  color: Colors.white.withValues(alpha: 0.5), size: 15),
              const SizedBox(width: 6),
              Text(
                'Filter by Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _FilterChip(
                label: 'All',
                active: active == TxFilter.all,
                activeColor: const Color(0xFFA8D8EA),
                activeTextColor: const Color(0x991E293B),
                inactiveTextColor: const Color(0xFFA8D8EA),
                onTap: () => onChanged(TxFilter.all),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Payments',
                active: active == TxFilter.payments,
                activeColor: const Color(0xFFB5FFD9),
                activeTextColor: const Color(0xFF0F172A),
                inactiveTextColor: const Color(0xFFB5FFD9),
                onTap: () => onChanged(TxFilter.payments),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Withdrawals',
                active: active == TxFilter.withdrawals,
                activeColor: const Color(0xFFD4B5FF),
                activeTextColor: const Color(0xFF0F172A),
                inactiveTextColor: const Color(0xFFD4B5FF),
                onTap: () => onChanged(TxFilter.withdrawals),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Purchases',
                active: active == TxFilter.fund,
                activeColor: const Color(0xFFA8D8EA),
                activeTextColor: const Color(0x991E293B),
                inactiveColor: const Color(0x1AA8D8EA),
                inactiveTextColor: const Color(0xB3A8D8EA),
                onTap: () => onChanged(TxFilter.fund),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final Color? inactiveColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeTextColor,
    required this.inactiveTextColor,
    this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : (inactiveColor ?? Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? activeColor
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}

// ── Transaction Card ──────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: _buildIcon()),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx.amount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tx.type == TxType.earning
                          ? const Color(0xFFB5FFD9)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: tx.status),
                ],
              ),
            ],
          ),

          if (_hasDetails) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x4D0A0E27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _detailRows,
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasDetails =>
      tx.jobDate != null || tx.method != null || tx.course != null;

  Widget get _detailRows {
    if (tx.type == TxType.earning) {
      return Column(
        children: [
          _DetailRow(label: 'Job Date', value: tx.jobDate ?? ''),
          const SizedBox(height: 6),
          _DetailRow(label: 'Hours Worked', value: tx.hoursWorked ?? ''),
          const SizedBox(height: 6),
          _DetailRow(label: 'Hourly Rate', value: tx.hourlyRate ?? ''),
        ],
      );
    } else if (tx.type == TxType.withdrawal) {
      return Column(
        children: [
          _DetailRow(label: 'Method', value: tx.method ?? ''),
          const SizedBox(height: 6),
          _DetailRow(label: 'Account', value: tx.account ?? ''),
        ],
      );
    } else {
      return _DetailRow(label: 'Course', value: tx.course ?? '');
    }
  }

  Color get _iconBg {
    switch (tx.type) {
      case TxType.earning:
        return const Color(0x33B5FFD9);
      case TxType.withdrawal:
        return const Color(0x33A8D8EA);
      case TxType.purchase:
        return const Color(0x1AD4B5FF);
    }
  }

  Widget _buildIcon() {
    switch (tx.type) {
      case TxType.earning:
        return SvgPicture.asset(
          'assets/receive-icon.svg',
          width: 20, height: 20,
          colorFilter: const ColorFilter.mode(Color(0xFFB5FFD9), BlendMode.srcIn),
        );
      case TxType.withdrawal:
        return SvgPicture.asset(
          'assets/withdraw-icon.svg',
          width: 20, height: 20,
          colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn),
        );
      case TxType.purchase:
        return SvgPicture.asset(
          'assets/card_icon.svg',
          width: 20, height: 20,
          colorFilter: const ColorFilter.mode(Color(0xFFD4B5FF), BlendMode.srcIn),
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0x33D4B5FF)
            : const Color(0x1AB5FFD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isPending
              ? const Color(0xFFD4B5FF)
              : const Color(0xFFB5FFD9),
        ),
      ),
    );
  }
}
