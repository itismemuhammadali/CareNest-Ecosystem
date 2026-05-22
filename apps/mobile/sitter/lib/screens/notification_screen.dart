import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<void> _markAllAsRead(List<Map<String, dynamic>> rows) async {
    final repo = NotificationsRepository(Supabase.instance.client);
    for (final r in rows) {
      if (r['read_at'] != null) continue;
      final id = r['id']?.toString();
      if (id == null) continue;
      await repo.markRead(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB30F172A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Notification',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: NotificationsRepository(Supabase.instance.client)
                        .myNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      final rows =
                          List<Map<String, dynamic>>.from(snapshot.data ?? []);
                      rows.sort((a, b) {
                        final ta = a['created_at']?.toString() ?? '';
                        final tb = b['created_at']?.toString() ?? '';
                        return tb.compareTo(ta);
                      });
                      final unread =
                          rows.where((r) => r['read_at'] == null).length;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
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
                                    fontSize: 13,
                                    color: Color(0x99A8D8EA),
                                  ),
                                ),
                                if (unread > 0)
                                  GestureDetector(
                                    onTap: () => _markAllAsRead(rows),
                                    child: const Text(
                                      'Mark all as read',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFA8D8EA),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (rows.isEmpty)
                              const Text(
                                'No notifications yet.',
                                style: TextStyle(color: Colors.white70),
                              )
                            else
                              ...rows.map((n) {
                                final created = n['created_at'] != null
                                    ? DateTime.tryParse(
                                        n['created_at'].toString(),
                                      )
                                    : null;
                                final time = created != null
                                    ? DateFormat.yMMMd()
                                        .add_jm()
                                        .format(created.toLocal())
                                    : '';
                                final unreadRow = n['read_at'] == null;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNotificationCard(
                                    title:
                                        (n['title'] ?? 'Notification').toString(),
                                    description: (n['body'] ?? '').toString(),
                                    time: time,
                                    isUnread: unreadRow,
                                  ),
                                );
                              }),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x991E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0x1AA8D8EA),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'You can manage notification preferences in Privacy Settings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0x99A8D8EA),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2D3E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/message-icon.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFA8D8EA),
                  BlendMode.srcIn,
                ),
              ),
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
                    color: Color(0x99A8D8EA),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
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
