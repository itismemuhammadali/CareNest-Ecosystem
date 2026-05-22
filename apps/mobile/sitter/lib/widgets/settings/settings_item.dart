import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsItem extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    this.icon,
    this.svgAsset,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  }) : assert(icon != null || svgAsset != null,
            'Either icon or svgAsset must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33A8D8EA), width: 1.09),
        ),
        child: Row(
          children: [
            svgAsset != null
                ? SvgPicture.asset(
                    svgAsset!,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0x99A8D8EA),
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: const Color(0x99A8D8EA), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            trailing ??
                const Icon(Icons.chevron_right,
                    color: Color(0x99A8D8EA), size: 20),
          ],
        ),
      ),
    );
  }
}
