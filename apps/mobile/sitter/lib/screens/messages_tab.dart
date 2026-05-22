import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/messages/message_search_bar.dart';
import '../widgets/messages/message_list_item.dart';
import '../utils/custom_page_route.dart';
import 'chat_screen.dart';

class MessagesTab extends StatelessWidget {
  final ValueChanged<int> onNavTap;
  const MessagesTab({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Secure conversations with families',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const MessageSearchBar(),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ConversationsRepository(Supabase.instance.client)
                      .sitterConversations(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                      );
                    }
                    final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                    if (rows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No conversations yet. Apply and get hired to chat.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      );
                    }
                    return Column(
                      children: rows.map((c) {
                        final id = c['id']?.toString() ?? '';
                        final jobId = c['job_id']?.toString() ?? '';
                        final created = c['created_at'] != null
                            ? DateTime.tryParse(c['created_at'].toString())
                            : null;
                        final time = created != null
                            ? DateFormat.yMMMd().add_jm().format(created.toLocal())
                            : '';
                        // S9: Check real unread count per conversation
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FutureBuilder<int>(
                            future: id.isEmpty
                                ? Future.value(0)
                                : ConversationsRepository(Supabase.instance.client)
                                    .unreadCountForConversation(id),
                            builder: (ctx, unreadSnap) => MessageListItem(
                              name: 'Family · job ${jobId.length > 6 ? jobId.substring(0, 6) : jobId}…',
                              preview: 'Tap to view conversation',
                              time: time,
                              isUnread: (unreadSnap.data ?? 0) > 0,
                              onTap: id.isEmpty
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        CustomPageRoute(
                                          builder: (_) => ChatScreen(
                                            familyName: 'Family',
                                            conversationId: id,
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
