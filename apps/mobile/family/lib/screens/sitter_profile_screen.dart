import 'package:flutter/material.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hire_sitter_step1_screen.dart';
import 'sitter_chat_screen.dart';
import 'sitter_public_profile_screen.dart';

class SitterProfileScreen extends StatefulWidget {
  final String? sitterUserId;
  const SitterProfileScreen({super.key, this.sitterUserId});

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  int _selectedTabIndex = 0;
  Map<String, dynamic>? _sitter;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    final uid = widget.sitterUserId;
    if (uid != null && uid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SitterPublicProfileScreen(sitterUserId: uid)),
        );
      });
    } else {
      _loadDemoSitter();
    }
  }

  Future<void> _loadDemoSitter() async {
    try {
      final sitters = await SittersRepository(Supabase.instance.client).listActiveSitters(limit: 1);
      if (sitters.isNotEmpty && mounted) {
        final s = sitters.first;
        final userId = s['user_id']?.toString();
        Map<String, dynamic>? u;
        String? convId;
        if (userId != null) {
          u = await ProfileRepository(Supabase.instance.client).currentUserRow();
          try {
            final rows = await Supabase.instance.client
                .from('conversations')
                .select('id')
                .eq('sitter_id', userId)
                .limit(1);
            final list = rows as List?;
            if (list != null && list.isNotEmpty) {
              convId = list.first['id']?.toString();
            }
          } catch (_) {}
        }
        setState(() { _sitter = s; _user = u; _conversationId = convId; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name {
    final n = _user?['full_name']?.toString();
    return (n != null && n.isNotEmpty) ? n : 'Sitter';
  }

  String get _age {
    final dob = _sitter?['date_of_birth']?.toString();
    if (dob == null) return '';
    final d = DateTime.tryParse(dob);
    if (d == null) return '';
    final age = (){final n=DateTime.now();return (n.year-d.year)-((n.month<d.month||(n.month==d.month&&n.day<d.day))?1:0);}();
    return '$age years old';
  }

  String get _rate {
    final r = _sitter?['hourly_rate'];
    if (r == null) return 'Rate TBD';
    return '\$${r}/hr';
  }

  String get _bio => _sitter?['bio']?.toString() ?? '';

  String? get _avatarUrl => _user?['avatar_url']?.toString();

  List<String> get _photoUrls {
    final photos = _sitter?['photos'];
    if (photos is List && photos.isNotEmpty) {
      return photos.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    final avatar = _avatarUrl;
    if (avatar != null && avatar.isNotEmpty) return [avatar];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sitterUserId != null && widget.sitterUserId!.isNotEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/screen-bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
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
          Column(
            children: [
              const Header2(title: 'Profile'),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x1A1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0x33FFFFFF), width: 1.09),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                            ? Image.network(
                                                _avatarUrl!,
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                                              )
                                            : _avatarPlaceholder(),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(_name,
                                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                                                ),
                                                const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                                              ],
                                            ),
                                            if (_age.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(_age, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                            ],
                                            const SizedBox(height: 10),
                                            _badge(Icons.check_circle_outline, 'Admin Verified', const Color(0xFF10B981)),
                                            const SizedBox(height: 6),
                                            _badge(Icons.shield_outlined, 'Background Checked', const Color(0xFF93C5FD)),
                                            const SizedBox(height: 6),
                                            _badge(Icons.school_outlined, 'Certified', const Color(0xFFC4B5FD)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [Color(0x1AA8D8EA), Color(0x1AD4A5D8)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Hourly Rate', style: TextStyle(fontSize: 13, color: Colors.white60)),
                                        Text(_rate,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFC8F0FF))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text('Photos & Moments',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: _photoUrls.isEmpty
                                  ? Center(
                                      child: Text('No photos yet',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _photoUrls.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (_, i) => _networkPhotoTile(_photoUrls[i]),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _tabBtn('About', 0),
                                  const SizedBox(width: 8),
                                  _tabBtn('Experience', 1),
                                  const SizedBox(width: 8),
                                  _tabBtn('Reviews', 2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_selectedTabIndex == 0)
                              Text(
                                _bio.isNotEmpty ? _bio : 'No bio provided yet.',
                                style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.6),
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0A0F1E),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 53,
                child: OutlinedButton(
                  onPressed: _conversationId != null
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SitterChatScreen(
                              conversationId: _conversationId!,
                              avatarUrl: _avatarUrl,
                              chatTitle: _name,
                            )),
                          )
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hire first to start messaging.')),
                          ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: _conversationId != null ? 0.3 : 0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Message',
                      style: TextStyle(
                        color: _conversationId != null ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HireSitterStep1Screen(
                      sitterName: _name,
                      hourlyRate: _rate,
                      rating: '—',
                      jobCount: '—',
                      sitterAvatarUrl: _avatarUrl,
                    )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Hire • $_rate',
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
    width: 90,
    height: 90,
    color: const Color(0xFF1E293B),
    child: const Icon(Icons.person, color: Colors.white38, size: 40),
  );

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _networkPhotoTile(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      url,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 100,
        height: 100,
        color: const Color(0xFF1E293B),
        child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 30),
      ),
    ),
  );

  Widget _tabBtn(String label, int index) {
    final sel = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFC8F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sel ? const Color(0xFFC8F0FF) : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? const Color(0xFF0F172A) : Colors.white)),
      ),
    );
  }
}
