import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TransactionType { earning, withdrawal, purchase }

class TransactionItem extends StatelessWidget {
  final TransactionType type;
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  const TransactionItem({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.status = 'completed',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        children: [
          // Icon
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

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0x99A8D8EA),
                  ),
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: type == TransactionType.earning
                      ? const Color(0xFFB5FFD9)
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x33B5FFD9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB5FFD9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _iconBg {
    switch (type) {
      case TransactionType.earning:
        return const Color(0x33B5FFD9);
      case TransactionType.withdrawal:
        return const Color(0x33A8D8EA);
      case TransactionType.purchase:
        return const Color(0x1AD4B5FF);
    }
  }

  Widget _buildIcon() {
    switch (type) {
      case TransactionType.earning:
        return SvgPicture.asset(
          'assets/receive-icon.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFFB5FFD9),
            BlendMode.srcIn,
          ),
        );
      case TransactionType.withdrawal:
        return SvgPicture.asset(
          'assets/withdraw-icon.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFFA8D8EA),
            BlendMode.srcIn,
          ),
        );
      case TransactionType.purchase:
        return SvgPicture.asset(
          'assets/card_icon.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFFD4B5FF),
            BlendMode.srcIn,
          ),
        );
    }
  }
}
