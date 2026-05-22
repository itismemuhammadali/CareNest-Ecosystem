import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SitterChatScreen extends StatefulWidget {
  final String? conversationId;
  final String chatTitle;
  final String? avatarUrl;

  const SitterChatScreen({
    super.key,
    this.conversationId,
    this.chatTitle = 'Chat',
    this.avatarUrl,
  });

  @override
  State<SitterChatScreen> createState() => _SitterChatScreenState();
}

class _SitterChatScreenState extends State<SitterChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final conv = widget.conversationId;
    if (conv == null || conv.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat will be available once you hire this sitter.'),
          ),
        );
      }
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/screen-bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [
                    Color(0xCC0F172A),
                    Color(0xE60F172A),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(color: Color(0x1AFFFFFF), height: 1, thickness: 1),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.conversationId == null || widget.conversationId!.isEmpty
                        ? const Stream<List<Map<String, dynamic>>>.empty()
                        : MessagesRepository(Supabase.instance.client)
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final m = rows[i];
                          final body = m['body']?.toString() ?? '';
                          final sid = m['sender_id']?.toString();
                          final mine = uid != null && sid == uid;
                          final ts = m['created_at'] != null
                              ? DateTime.tryParse(m['created_at'].toString())
                              : null;
                          final time = ts != null ? DateFormat.jm('en_US').format(ts.toLocal()) : '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: mine
                                ? _buildSentMessage(body, time)
                                : _buildReceivedMessage(body, time),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF1E293B),
                backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                    ? NetworkImage(widget.avatarUrl!) as ImageProvider
                    : null,
                child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white38, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Secure chat',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0x991E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xCCFFFFFF),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x80FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0x1AA8D8EA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF10B981),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x80FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF03060F).withValues(alpha: 0.8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(
                  color: Color(0x66FFFFFF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (widget.conversationId == null || widget.conversationId!.isEmpty) ? null : _send,
            child: SvgPicture.asset(
              'assets/send_button.svg',
              width: 46,
              height: 46,
            ),
          ),
        ],
      ),
    );
  }
}
