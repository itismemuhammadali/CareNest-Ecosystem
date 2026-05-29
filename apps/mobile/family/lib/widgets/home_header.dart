import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHeader extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final Widget? searchBar;

  const HomeHeader({
    super.key,
    this.onProfileTap,
    this.onNotificationTap,
    this.searchBar,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _displayName = '';
  String? _avatarUrl;
  int _unreadCount = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _subscribeProfile();
    _subscribeNotifications();
  }

  void _subscribeProfile() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _profileSub = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .listen((rows) {
      if (!mounted || rows.isEmpty) return;
      final user = rows.first;
      final fullName = user['full_name']?.toString() ?? '';
      final first = fullName.trim().split(' ').first;
      setState(() {
        _displayName = first;
        _avatarUrl = user['avatar_url'] as String?;
      });
    });
  }

  void _subscribeNotifications() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _notifSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .listen((rows) {
      if (!mounted) return;
      final unread = rows.where((r) => r['read_at'] == null).length;
      setState(() => _unreadCount = unread);
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 24, top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar with proper image loading
                      _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _avatarUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white12,
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/profile-icon.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white12,
                              ),
                              child: SvgPicture.asset(
                                'assets/profile-icon.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
                              ),
                            ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back,',
                              style: TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            _displayName.isNotEmpty ? _displayName : '...',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: widget.onNotificationTap,
                child: Stack(
                  children: [
                    SvgPicture.asset('assets/notification-icon.svg', width: 32, height: 32,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                              color: Color(0xFFA8D8EA), shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF000000), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.searchBar != null) ...[
            const SizedBox(height: 12),
            widget.searchBar!,
          ],
        ],
      ),
    );
  }
}
