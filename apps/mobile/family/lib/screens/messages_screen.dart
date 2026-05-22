import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/bottom_nav_bar.dart';
import 'package:star_sitter_family/widgets/home_header.dart';
import 'package:star_sitter_family/widgets/search_bar.dart' as search_bar;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifications_screen.dart';
import 'sitter_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final bool embedded;
  const MessagesScreen({super.key, this.embedded = false});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedIndex = 2;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Home header with profile, notification, and search bar (extends behind status bar)
              HomeHeader(
                onNotificationTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                searchBar: search_bar.CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search Chats',
                ),
              ),
              // Content scrollable area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connect and communicate with experts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: ConversationsRepository(Supabase.instance.client)
                            .familyConversations(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              '${snapshot.error}',
                              style: const TextStyle(color: Colors.white70),
                            );
                          }
                          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                          if (rows.isEmpty) {
                            return const Text(
                              'No conversations yet. Hire a sitter to start messaging.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
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
                              return _ConversationTile(
                                key: ValueKey(id),
                                conversationId: id,
                                jobId: jobId,
                                time: time,
                                onOpen: id.isEmpty
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => SitterChatScreen(
                                              conversationId: id,
                                              chatTitle: 'Sitter chat',
                                            ),
                                          ),
                                        ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Security info
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
                          '🔒 All messages are encrypted and secure. Contact information is never shared.',
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
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
    );
  }

  Widget _buildChatCard({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required String imagePath,
    VoidCallback? onOpen,
  }) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
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
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA8D8EA),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _ConversationTile extends StatefulWidget {
  final String conversationId;
  final String jobId;
  final String time;
  final VoidCallback? onOpen;

  const _ConversationTile({
    super.key,
    required this.conversationId,
    required this.jobId,
    required this.time,
    this.onOpen,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  String _title = 'Loading…';

  @override
  void initState() {
    super.initState();
    _loadTitle();
  }

  Future<void> _loadTitle() async {
    if (widget.jobId.isEmpty) {
      if (mounted) setState(() => _title = 'Conversation');
      return;
    }
    final row = await ConversationsRepository(Supabase.instance.client)
        .fetchJobTitle(widget.jobId);
    if (mounted) {
      setState(() => _title = row?['title']?.toString() ?? 'Job chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x991E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/homeScreenPic1.png')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('Tap to open chat', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Text(widget.time, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
