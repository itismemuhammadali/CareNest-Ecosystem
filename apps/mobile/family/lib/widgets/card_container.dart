import 'package:flutter/material.dart';

/// Reusable card container widget with consistent styling
class CardContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final bool showBorder;

  const CardContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor = const Color(0x991E293B),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}
