import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageListItem extends StatelessWidget {
  final String name;
  final String preview;
  final String time;
  final bool isUnread;
  final String? avatarAsset;
  final VoidCallback? onTap;

  const MessageListItem({
    super.key,
    required this.name,
    required this.preview,
    required this.time,
    this.isUnread = false,
    this.avatarAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF2A2D3E),
              backgroundImage: avatarAsset != null
                  ? AssetImage(avatarAsset!)
                  : null,
              child: avatarAsset == null
                  ? SvgPicture.asset(
                      'assets/profile-icon.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.white38,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0x99A8D8EA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Time + unread dot
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
