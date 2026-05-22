import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/messages/message_search_bar.dart';
import '../widgets/messages/message_list_item.dart';
import '../utils/custom_page_route.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _currentNavIndex = 2;

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Messages',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Secure conversations with families',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
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
                          stream: ConversationsRepository(Supabase.instance.client).sitterConversations(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('${snapshot.error}', style: const TextStyle(color: Colors.white70));
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
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: MessageListItem(
                                    name: 'Family · job ${jobId.length > 6 ? jobId.substring(0, 6) : jobId}…',
                                    preview: 'Secure conversation',
                                    time: time,
                                    isUnread: false,
                                    avatarAsset: null,
                                    onTap: id.isEmpty
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              CustomPageRoute(
                                                builder: (_) => ChatScreen(
                                                  familyName: 'Family',
                                                  avatarAsset: null,
                                                  conversationId: id,
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
                BottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _currentNavIndex = index);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
