import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum NotificationType { application, message, hired, upcoming }

class NotificationItem extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;

  const NotificationItem({
    super.key,
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (type == NotificationType.hired ||
                      type == NotificationType.upcoming)
                  ? const Color(0xFF1A1D2E)
                  : const Color(0xFF2A2D3E),
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildIcon()),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0x99A8D8EA),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // Unread dot
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFA8D8EA),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (type) {
      case NotificationType.message:
        return SvgPicture.asset(
          'assets/message-icon.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFFD4A5D8),
            BlendMode.srcIn,
          ),
        );
      case NotificationType.hired:
        return SvgPicture.asset(
          'assets/tick-icon.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF4ADE80),
            BlendMode.srcIn,
          ),
        );
      case NotificationType.application:
        return SvgPicture.asset(
          'assets/certificate-icon.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFFA8D8EA),
            BlendMode.srcIn,
          ),
        );
      case NotificationType.upcoming:
        return const Icon(Icons.access_time_outlined,
            color: Color(0xFFFBBF24), size: 22);
    }
  }
}
