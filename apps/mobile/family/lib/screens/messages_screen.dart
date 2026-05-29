import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
}

class _ConversationTile extends StatefulWidget {
  final String conversationId;
  final String jobId;
  final String time;

  const _ConversationTile({
    super.key,
    required this.conversationId,
    required this.jobId,
    required this.time,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  String _title = 'Loading…';
  String _jobInfo = '';
  String? _avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.conversationId.isEmpty) {
      if (mounted) {
        setState(() {
          _title = 'Conversation';
          _loading = false;
        });
      }
      return;
    }
    
    final repo = ConversationsRepository(Supabase.instance.client);
    final results = await Future.wait([
      repo.fetchPartnerProfile(widget.conversationId),
      repo.fetchJobDetails(widget.conversationId),
    ]);
    
    if (mounted) {
      setState(() {
        final profile = results[0] as Map<String, dynamic>?;
        if (profile != null) {
          _title = profile['full_name']?.toString() ?? 'Sitter';
          _avatarUrl = profile['avatar_url']?.toString();
        } else {
          _title = 'Sitter';
        }
        
        final jobDetails = results[1] as Map<String, dynamic>?;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SitterChatScreen(
                conversationId: widget.conversationId,
                chatTitle: _title,
                avatarUrl: _avatarUrl,
                jobInfo: _jobInfo,
              ),
            ),
          );
        },
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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1E293B),
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!) as ImageProvider
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? SvgPicture.asset(
                        'assets/profile-icon.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white38,
                          BlendMode.srcIn,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      _jobInfo.isNotEmpty ? _jobInfo : 'Tap to open chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
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
