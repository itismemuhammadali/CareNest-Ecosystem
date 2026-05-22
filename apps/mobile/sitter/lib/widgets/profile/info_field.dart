import 'package:flutter/material.dart';

class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0x99A8D8EA),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 14),
          Divider(
            color: Colors.white.withValues(alpha: 0.1),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
