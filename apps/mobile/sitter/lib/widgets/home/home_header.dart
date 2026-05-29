import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/custom_page_route.dart';
import '../../screens/notification_screen.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _firstName = '';
  String? _avatarUrl;
  int _unreadCount = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _subscribeNotifications();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ProfileRepository(Supabase.instance.client);
      final user = await repo.currentUserRow();
      final fullName = user?['full_name']?.toString() ?? '';
      final first = fullName.trim().split(' ').first;
      if (mounted) {
        setState(() {
          _firstName = first;
          _avatarUrl = user?['avatar_url'] as String?;
        });
      }
    } catch (_) {}
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
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: TextStyle(fontSize: 13, color: Colors.white70)),
              Text(
                _firstName.isNotEmpty ? _firstName : '...',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
              CustomPageRoute(builder: (_) => const NotificationScreen())),
          child: Stack(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: SvgPicture.asset('assets/bell-icon.svg', width: 22, height: 22,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: Color(0xFFC8F0FF), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
