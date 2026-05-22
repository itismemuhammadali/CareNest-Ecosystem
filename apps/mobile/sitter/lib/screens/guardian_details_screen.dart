import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile/info_field.dart';
import '../utils/custom_page_route.dart';
import 'edit_guardian_details_screen.dart';

class GuardianDetailsScreen extends StatefulWidget {
  const GuardianDetailsScreen({super.key});

  @override
  State<GuardianDetailsScreen> createState() => _GuardianDetailsScreenState();
}

class _GuardianDetailsScreenState extends State<GuardianDetailsScreen> {
  Map<String, dynamic>? _row;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final res = await Supabase.instance.client
        .from('guardian_consents')
        .select()
        .eq('sitter_id', uid)
        .maybeSingle();
    if (mounted) {
      setState(() {
        _row = res == null ? null : Map<String, dynamic>.from(res as Map);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Guardian Details',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View guardian information',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        builder: (_) => EditGuardianDetailsScreen(existing: _row),
                                      ),
                                    );
                                    _load();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0x33A8D8EA),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/edit-icon.svg',
                                          width: 18,
                                          height: 18,
                                          colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Edit',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFA8D8EA)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                                decoration: BoxDecoration(
                                  color: const Color(0x991E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InfoField(label: 'Guardian Name', value: _row?['guardian_name']?.toString() ?? '—'),
                                    InfoField(label: 'Guardian Email', value: _row?['guardian_email']?.toString() ?? '—'),
                                    InfoField(label: 'Guardian Phone', value: _row?['guardian_phone']?.toString() ?? '—'),
                                    InfoField(
                                      label: 'Relationship',
                                      value: _row?['relationship']?.toString() ?? 'Not provided',
                                      showDivider: false,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
