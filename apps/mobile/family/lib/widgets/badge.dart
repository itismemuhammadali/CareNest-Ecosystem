import 'package:flutter/material.dart';

enum BadgeType {
  verified,
  certified,
  available,
  completed,
  pending,
  custom,
}

/// Reusable badge widget for status, verification, and availability indicators
class Badge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final double borderRadius;

  const Badge({
    super.key,
    required this.label,
    required this.type,
    this.borderRadius = 20,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case BadgeType.verified:
        return const Color(0xFF166534);
      case BadgeType.certified:
        return const Color(0xFF1E40AF);
      case BadgeType.available:
        return const Color(0xFF0369A1);
      case BadgeType.completed:
        return const Color(0xFF4B5563);
      case BadgeType.pending:
        return const Color(0xFF78350F);
      case BadgeType.custom:
        return const Color(0xFF1E293B);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case BadgeType.verified:
        return const Color(0xFF4ADE80);
      case BadgeType.certified:
        return const Color(0xFF60A5FA);
      case BadgeType.available:
        return const Color(0xFF06B6D4);
      case BadgeType.completed:
        return const Color(0xFFCBD5E1);
      case BadgeType.pending:
        return const Color(0xFFFBBF24);
      case BadgeType.custom:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: _getTextColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
