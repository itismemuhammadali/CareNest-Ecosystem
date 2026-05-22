import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/wallet/wallet_balance_card.dart';
import '../widgets/wallet/wallet_stats_row.dart';
import '../widgets/wallet/wallet_quick_actions.dart';
import '../widgets/wallet/transaction_item.dart';
import '../utils/custom_page_route.dart';
import '../screens/all_transactions_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletRow;
  bool _walletLoading = true;
  bool _walletError = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (mounted) setState(() { _walletLoading = true; _walletError = false; });
    try {
      final w = await WalletRepository(Supabase.instance.client).myWallet();
      if (mounted) setState(() { _walletRow = w; _walletLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _walletLoading = false; _walletError = true; });
    }
  }

  // S7: Three explicit states for balance display
  String _money(dynamic v) {
    if (_walletLoading) return '…';
    if (_walletError) return 'Error';
    if (v == null) return '\$0.00';
    final n = double.tryParse(v.toString());
    return n != null ? '\$${n.toStringAsFixed(2)}' : '\$0.00';
  }

  @override
  Widget build(BuildContext context) {
    final avail = _money(_walletRow?['available_balance']);
    final pend = _money(_walletRow?['pending_balance']);
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
                        'My Wallet',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your earnings and payments',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
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

                  if (_walletError)
                    GestureDetector(
                      onTap: _loadWallet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Failed to load balance — tap to retry',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                      ),
                    ),
                  WalletBalanceCard(
                    displayAvailable: avail,
                    displayPending: pend,
                  ),
                  const SizedBox(height: 16),

                  const WalletStatsRow(),
                  const SizedBox(height: 16),

                  const WalletQuickActions(),
                  const SizedBox(height: 24),

                  // Recent Transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          CustomPageRoute(
                              builder: (_) =>
                                  const AllTransactionsScreen()),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA8D8EA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: WalletRepository(Supabase.instance.client).ledgerStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          '${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        );
                      }
                      final rows = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                      if (rows.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No ledger entries yet. Complete a job (clock in/out) to earn.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        );
                      }
                      rows.sort((a, b) {
                        final ta = a['created_at']?.toString() ?? '';
                        final tb = b['created_at']?.toString() ?? '';
                        return tb.compareTo(ta);
                      });
                      return Column(
                        children: rows.take(12).map((r) {
                          final title = (r['type'] ?? 'entry').toString();
                          final amt = r['amount']?.toString() ?? '';
                          final ref = (r['reference_type'] ?? '').toString();
                          final txType = title == 'earning'
                              ? TransactionType.earning
                              : title == 'withdrawal'
                                  ? TransactionType.withdrawal
                                  : TransactionType.purchase;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TransactionItem(
                              type: txType,
                              title: title,
                              subtitle: ref,
                              amount: amt.startsWith('\$') ? amt : '\$$amt',
                              status: 'posted',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Info notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1AD4B5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0x4DD4B5FF), width: 1.09),
                    ),
                    child: const Text(
                      '💡 Payments from families are processed within 24 hours after job completion. Guardian approval may be required for withdrawals.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD4B5FF),
                        height: 1.5,
                      ),
                    ),
                  ),
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
