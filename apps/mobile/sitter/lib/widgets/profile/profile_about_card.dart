import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileAboutCard extends StatefulWidget {
  const ProfileAboutCard({super.key});

  @override
  State<ProfileAboutCard> createState() => _ProfileAboutCardState();
}

class _ProfileAboutCardState extends State<ProfileAboutCard> {
  String _bio = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sp = await ProfileRepository(Supabase.instance.client).sitterProfile();
      if (!mounted) return;
      setState(() {
        _bio = sp?['bio']?.toString().trim() ?? '';
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: _loaded
          ? Text(
              _bio.isNotEmpty
                  ? _bio
                  : 'No bio added yet. Edit your profile to add one.',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0x99A8D8EA),
                height: 1.5,
              ),
            )
          : const Text(
              '…',
              style: TextStyle(fontSize: 15, color: Color(0x99A8D8EA)),
            ),
    );
  }
}
