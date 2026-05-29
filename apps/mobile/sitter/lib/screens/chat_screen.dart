import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/messages/chat_bubble.dart';
import '../widgets/messages/chat_input_bar.dart';

class ChatMessage {
  final String text;
  final String time;
  final bool isMe;

  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class ChatScreen extends StatefulWidget {
  final String familyName;
  final String subtitle;
  final String? avatarAsset;
  final String? avatarUrl;
  /// When set, loads live messages from Supabase (BACKEND.md §17).
  final String? conversationId;
  /// Job information to display in the header
  final String jobInfo;

  const ChatScreen({
    super.key,
    required this.familyName,
    this.subtitle = 'Secure Chat',
    this.avatarAsset,
    this.avatarUrl,
    this.conversationId,
    this.jobInfo = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = <ChatMessage>[];
  }

  Future<void> _onSend(String text) async {
    final conv = widget.conversationId;
    if (conv != null && conv.isNotEmpty) {
      try {
        await MessagesRepository(Supabase.instance.client).send(
          conversationId: conv,
          body: text,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
      return;
    }
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        time: _currentTime(),
        isMe: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          // Gradient overlay
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
                // Back button row
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
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Family header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF2A2D3E),
                        backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                            ? NetworkImage(widget.avatarUrl!)
                            : (widget.avatarAsset != null
                                ? AssetImage(widget.avatarAsset!)
                                : null) as ImageProvider?,
                        child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty) && widget.avatarAsset == null
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.familyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.jobInfo.isNotEmpty ? widget.jobInfo : widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0x99A8D8EA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  thickness: 1,
                  height: 1,
                ),

                Expanded(
                  child: widget.conversationId != null && widget.conversationId!.isNotEmpty
                      ? StreamBuilder<List<Map<String, dynamic>>>(
                          stream: MessagesRepository(Supabase.instance.client)
                              .stream(widget.conversationId!),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  '${snapshot.error}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }
                            final rows = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                            rows.sort((a, b) {
                              final ta = a['created_at']?.toString() ?? '';
                              final tb = b['created_at']?.toString() ?? '';
                              return ta.compareTo(tb);
                            });
                            final uid = Supabase.instance.client.auth.currentUser?.id;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                            return ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final m = rows[index];
                                final body = m['body']?.toString() ?? '';
                                final mine = uid != null && m['sender_id']?.toString() == uid;
                                final ts = m['created_at'] != null
                                    ? DateTime.tryParse(m['created_at'].toString())
                                    : null;
                                final time = ts != null ? DateFormat.jm('en_US').format(ts.toLocal()) : '';
                                return ChatBubble(
                                  message: body,
                                  time: time,
                                  isMe: mine,
                                );
                              },
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No conversation selected.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ),
                ),

                ChatInputBar(onSend: (s) => _onSend(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
