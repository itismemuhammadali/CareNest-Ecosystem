import 'package:flutter/material.dart';

/// Reusable progress indicator with step label
class ProgressIndicatorWithLabel extends StatelessWidget {
  final double value;
  final String label;
  final Color backgroundColor;
  final Color valueColor;
  final double minHeight;
  final double borderRadius;

  const ProgressIndicatorWithLabel({
    super.key,
    required this.value,
    required this.label,
    this.backgroundColor = const Color(0x26FFFFFF),
    this.valueColor = const Color(0xFFC8F0FF),
    this.minHeight = 4,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            minHeight: minHeight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
