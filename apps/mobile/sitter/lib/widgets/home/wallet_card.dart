import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/custom_page_route.dart';
import '../../screens/wallet_screen.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({super.key});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  String _balance = '\$0.00';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final w = await WalletRepository(Supabase.instance.client).myWallet();
      final avail = (w?['available_balance'] as num?)?.toDouble() ?? 0.0;
      if (mounted) setState(() => _balance = '\$${avail.toStringAsFixed(2)}');
    } catch (_) {
      if (mounted) setState(() => _balance = '\$0.00');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CustomPageRoute(builder: (_) => const WalletScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AA8D8EA), Color(0x1AA8D8EA)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AA8D8EA), width: 1.09),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0x4DB5FFD9), borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: SvgPicture.asset('assets/wallet-icon.svg', width: 22, height: 22,
                    colorFilter: const ColorFilter.mode(Color(0xFFB5FFD9), BlendMode.srcIn)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Wallet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xB3B5FFD9), Color(0xB3B5FFD9)],
                    ).createShader(bounds),
                    child: const Text('Manage earnings and\nwithdrawals',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_balance,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xB3B5FFD9), Color(0xB3B5FFD9)],
                  ).createShader(bounds),
                  child: const Text('Available', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
