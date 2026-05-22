import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markAllAsRead(List<Map<String, dynamic>> rows) async {
    await NotificationsRepository(Supabase.instance.client).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB30F172A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // Header with back button and title
              Header2(
                title: 'Notification',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Unread count and mark as read
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: NotificationsRepository(Supabase.instance.client)
                            .myNotifications(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              '${snapshot.error}',
                              style: const TextStyle(color: Colors.white70),
                            );
                          }
                          final rows = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                          rows.sort((a, b) {
                            final ta = a['created_at']?.toString() ?? '';
                            final tb = b['created_at']?.toString() ?? '';
                            return tb.compareTo(ta);
                          });
                          final unread = rows.where((r) => r['read_at'] == null).length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    unread == 0
                                        ? 'No unread notifications'
                                        : '$unread unread notification${unread > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (unread > 0)
                                    GestureDetector(
                                      onTap: () => _markAllAsRead(rows),
                                      child: const Text(
                                        'Mark all as read',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFC8F0FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (rows.isEmpty)
                                const Text(
                                  'No notifications yet.',
                                  style: TextStyle(color: Colors.white70),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: rows.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final n = rows[index];
                                    final created = n['created_at'] != null
                                        ? DateTime.tryParse(n['created_at'].toString())
                                        : null;
                                    final time = created != null
                                        ? DateFormat.yMMMd().add_jm().format(created.toLocal())
                                        : '';
                                    final unreadRow = n['read_at'] == null;
                                    return _buildNotificationCard(
                                      icon: 'assets/message-icon.svg',
                                      title: (n['title'] ?? 'Notification').toString(),
                                      description: (n['body'] ?? '').toString(),
                                      time: time,
                                      isUnread: unreadRow,
                                      iconColor: const Color(0xFFA8D8EA),
                                      isIconWidget: false,
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Privacy settings info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '💡 You can manage notification preferences in Privacy Settings',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String time,
    required bool isUnread,
    dynamic icon,
    Color? iconColor,
    bool isIconWidget = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isIconWidget)
            Icon(
              icon as IconData,
              color: iconColor ?? Colors.white54,
              size: 24,
            )
          else
            SvgPicture.asset(
              icon as String,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                iconColor ?? Colors.white54,
                BlendMode.srcIn,
              ),
            ),
          const SizedBox(width: 12),
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
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
