import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/custom_page_route.dart';
import 'withdrawal_success_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '100');

  double _available = 0;
  bool _loadingBalance = true;
  String? _balanceError;
  bool _submitting = false;
  String? _guardianConsentStatus;

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _fee => withdrawalFee(_amount);
  double get _total => withdrawalTotalDebit(_amount);

  void _setAmount(double value) {
    setState(() => _amountController.text = value.toStringAsFixed(0));
  }

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadGuardianStatus();
  }

  Future<void> _loadGuardianStatus() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final row = await Supabase.instance.client
          .from('sitter_profiles')
          .select('guardian_consent_status')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _guardianConsentStatus = row?['guardian_consent_status']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loadingBalance = true;
      _balanceError = null;
    });
    try {
      final w = await WalletRepository(Supabase.instance.client).myWallet();
      final v = parseWalletAvailableBalance(w?['available_balance']);
      if (!mounted) return;
      setState(() {
        _available = v;
        _loadingBalance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = '$e';
        _loadingBalance = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
                      const Text('Withdraw Funds',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Transfer money to your bank account',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Available balance card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available for Withdrawal',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.5))),
                              const SizedBox(height: 6),
                              Text(
                                _loadingBalance
                                    ? '…'
                                    : (_balanceError != null ? '—' : '\$${_available.toStringAsFixed(2)}'),
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text('Minimum withdrawal: \$10.00',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.35))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Withdrawal amount card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Withdrawal Amount',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 12),

                              // Input
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0x1AA8D8EA),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Text('\$',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white
                                                .withValues(alpha: 0.6))),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Quick amounts
                              Row(
                                children: [50, 100, 200, 300]
                                    .map((v) => Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8),
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _setAmount(v.toDouble()),
                                              child: Container(
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x1AA8D8EA),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0x4DA8D8EA),
                                                      width: 1.09),
                                                ),
                                                child: Text('\$$v',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                            0xFFA8D8EA))),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 10),

                              // Withdraw All
                              GestureDetector(
                                onTap: () => _setAmount(_available),
                                child: Container(
                                  width: double.infinity,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1AD4B5FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0x4DD4B5FF),
                                        width: 1.09),
                                  ),
                                  child: Text(
                                    'Withdraw All (\$${_available.toStringAsFixed(2)})',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFD4B5FF),
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Withdraw To card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Withdraw To',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text('Manage',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFFA8D8EA))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AA8D8EA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0x66A8D8EA),
                                      width: 1.09),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFA8D8EA),
                                            width: 2),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFA8D8EA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Manual Bank Transfer',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                        const Text('Admin processes payout',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Transaction Details card
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transaction Details',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 14),
                              _detailRow('Withdrawal Amount',
                                  '\$${_amount.toStringAsFixed(2)}',
                                  isTotal: false),
                              const SizedBox(height: 8),
                              _detailRow('Processing Fee (${(kDefaultWithdrawalFeeRate * 100).toStringAsFixed(0)}%)',
                                  '\$${_fee.toStringAsFixed(2)}',
                                  isTotal: false),
                              const SizedBox(height: 12),
                              Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  thickness: 1),
                              const SizedBox(height: 8),
                              _detailRow(
                                  'Total', '\$${_total.toStringAsFixed(2)}',
                                  isTotal: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Guardian notice
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset(
                                'assets/sheild-icon.svg',
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFD4B5FF),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Guardian approval is required for withdrawals.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFD4B5FF),
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 4),
                                    _GuardianStatusChip(status: _guardianConsentStatus),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom: Request Withdrawal + note
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _submitting || _loadingBalance || _balanceError != null
                            ? () {}
                            : () async {
                                final err = validateWithdrawalRequest(
                                  amount: _amount,
                                  available: _available,
                                );
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(err)),
                                  );
                                  return;
                                }
                                // S6: Require explicit confirmation before irreversible withdrawal
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: const Text('Confirm withdrawal', style: TextStyle(color: Colors.white)),
                                    content: Text(
                                      'Withdraw \$${_amount.toStringAsFixed(2)}? This cannot be undone.',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8D8EA)),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Confirm', style: TextStyle(color: Color(0xFF0F172A))),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !mounted) return;
                                setState(() => _submitting = true);
                                try {
                                  await WalletRepository(Supabase.instance.client).requestWithdrawal(
                                    amount: _amount,
                                    method: 'manual_bank',
                                    accountInfo: {
                                      'display': 'Manual Bank Transfer',
                                      'note': 'Admin processes payout via bank transfer.',
                                    },
                                    availableBalance: _available,
                                  );
                                  if (!mounted) return;
                                  await Navigator.push(
                                    context,
                                    CustomPageRoute(
                                      builder: (_) => WithdrawalSuccessScreen(
                                        amount: _amount.toStringAsFixed(2),
                                      ),
                                    ),
                                  );
                                } on ArgumentError catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message?.toString() ?? 'Invalid withdrawal')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Withdrawal failed: $e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _submitting = false);
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA8D8EA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _submitting ? 'Submitting…' : 'Request Withdrawal',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0x991E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Funds typically arrive in 1-3 business days',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1.09),
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 14 : 13,
                fontWeight:
                    isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5))),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : const Color(0x99A8D8EA))),
      ],
    );
  }
}

class _GuardianStatusChip extends StatelessWidget {
  const _GuardianStatusChip({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final String label;
    final Color color;
    switch (status) {
      case 'approved':
        label = 'Guardian: Approved';
        color = const Color(0xFF4ADE80);
        break;
      case 'rejected':
      case 'denied':
        label = 'Guardian: Denied';
        color = const Color(0xFFEF4444);
        break;
      case 'pending':
        label = 'Guardian: Pending approval';
        color = const Color(0xFFFBBF24);
        break;
      default:
        label = 'Guardian consent not submitted';
        color = const Color(0xFF94A3B8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
