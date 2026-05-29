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
                        final created = c['created_at'] != null
                            ? DateTime.tryParse(c['created_at'].toString())
                            : null;
                        final time = created != null
                            ? DateFormat.yMMMd().add_jm().format(created.toLocal())
                            : '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SitterConversationItem(
                            conversationId: id,
                            time: time,
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

class _SitterConversationItem extends StatefulWidget {
  final String conversationId;
  final String time;

  const _SitterConversationItem({
    required this.conversationId,
    required this.time,
  });

  @override
  State<_SitterConversationItem> createState() => _SitterConversationItemState();
}

class _SitterConversationItemState extends State<_SitterConversationItem> {
  String _partnerName = 'Family';
  String? _avatarUrl;
  String _jobInfo = '';
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.conversationId.isEmpty) return;
    final repo = ConversationsRepository(Supabase.instance.client);
    
    final results = await Future.wait([
      repo.fetchPartnerProfile(widget.conversationId),
      repo.unreadCountForConversation(widget.conversationId),
      repo.fetchJobDetails(widget.conversationId),
    ]);

    if (mounted) {
      setState(() {
        final profile = results[0] as Map<String, dynamic>?;
        if (profile != null) {
          _partnerName = profile['full_name']?.toString() ?? 'Family';
          _avatarUrl = profile['avatar_url']?.toString();
        }
        _unreadCount = results[1] as int;
        
        final jobDetails = results[2] as Map<String, dynamic>?;
        if (jobDetails != null) {
          final title = jobDetails['title']?.toString() ?? '';
          final date = jobDetails['date']?.toString() ?? '';
          final startTime = jobDetails['start_time']?.toString() ?? '';
          final numChildren = jobDetails['number_of_children']?.toString() ?? '';
          
          // Format job info: "Job Title • Date • Time • X kids"
          final parts = <String>[];
          if (title.isNotEmpty) parts.add(title);
          if (date.isNotEmpty) parts.add(date);
          if (startTime.isNotEmpty) parts.add(startTime);
          if (numChildren.isNotEmpty) parts.add('$numChildren kids');
          
          _jobInfo = parts.join(' • ');
        }
        
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return MessageListItem(
      name: _partnerName,
      preview: _jobInfo.isNotEmpty ? _jobInfo : 'Tap to view conversation',
      time: widget.time,
      isUnread: _unreadCount > 0,
      avatarUrl: _avatarUrl,
      onTap: () => Navigator.push(
        context,
        CustomPageRoute(
          builder: (_) => ChatScreen(
            familyName: _partnerName,
            conversationId: widget.conversationId,
            avatarUrl: _avatarUrl,
            jobInfo: _jobInfo,
          ),
        ),
      ),
    );
  }
}
