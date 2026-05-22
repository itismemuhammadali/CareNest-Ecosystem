import 'package:flutter/material.dart';
import '../../screens/earnings_screen.dart';
import '../../utils/custom_page_route.dart';

class WalletQuickActions extends StatelessWidget {
  const WalletQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionButton(
                icon: Icons.add,
                label: 'Buy Courses',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course purchases open when the catalog is published.'),
                    ),
                  );
                },
                bgColor: const Color(0x1AD4B5FF),
                borderColor: const Color(0x4DD4B5FF),
                iconColor: const Color(0xFFD4B5FF),
                textColor: Colors.white,
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionButton(
                icon: Icons.trending_up,
                label: 'View Earnings',
                onTap: () => Navigator.push(
                  context,
                  CustomPageRoute(
                    builder: (_) => const EarningsScreen(),
                  ),
                ),
                bgColor: const Color(0x1AB5FFD9),
                borderColor: const Color(0x4DB5FFD9),
                iconColor: const Color(0xFFB5FFD9),
                textColor: Colors.white,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color? iconColor;

  const _ActionButton({
    this.icon,
    required this.label,
    this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedIconColor = iconColor ?? textColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.09),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: resolvedIconColor, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
