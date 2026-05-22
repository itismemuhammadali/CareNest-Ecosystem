import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/certifications_screen.dart';
import '../../utils/custom_page_route.dart';

class CertificationCard extends StatefulWidget {
  const CertificationCard({super.key});

  @override
  State<CertificationCard> createState() => _CertificationCardState();
}

class _CertificationCardState extends State<CertificationCard> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final submissions = await Supabase.instance.client
          .from('certification_submissions')
          .select('status')
          .eq('sitter_id', uid);
      final total = Supabase.instance.client
          .from('courses')
          .select('id')
          .eq('status', 'published');
      final subList = (submissions as List?) ?? [];
      final approved = subList.where((s) => s['status'] == 'approved').length;
      final totalRes = await total;
      final totalCount = (totalRes as List?)?.length ?? 0;
      if (mounted) {
        setState(() {
          _progress = totalCount > 0 ? (approved / totalCount).clamp(0.0, 1.0) : 0.0;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _progress = 0.0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CustomPageRoute(
            builder: (_) => const CertificationsScreen(),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1AA8D8EA), Color(0x1AA8D8EA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1.09),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x4DA8D8EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/certificate-icon.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA8D8EA),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Certification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Required before applying to jobs',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
