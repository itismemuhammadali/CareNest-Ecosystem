import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    this.icon,
    this.svgAsset,
    required this.label,
    this.onTap,
  }) : assert(icon != null || svgAsset != null,
            'Either icon or svgAsset must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
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
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0x99A8D8EA), size: 20),
          ],
        ),
      ),
    );
  }
}
