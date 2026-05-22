import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable information box widget with icon and text
class InfoBox extends StatelessWidget {
  final String title;
  final String description;
  final String? iconPath;
  final IconData? iconData;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;

  const InfoBox({
    super.key,
    required this.title,
    required this.description,
    this.iconPath,
    this.iconData,
    this.backgroundColor = const Color(0x991E293B),
    this.textColor = Colors.white70,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconPath != null)
            SvgPicture.asset(
              iconPath!,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white54,
                BlendMode.srcIn,
              ),
            )
          else if (iconData != null)
            Icon(iconData, color: Colors.white54, size: 20)
          else
            const Icon(Icons.info, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    height: 1.4,
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
