import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile/info_field.dart';
import '../utils/custom_page_route.dart';
import 'edit_personal_information_screen.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sitter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ProfileRepository(Supabase.instance.client);
    final user = await repo.currentUserRow();
    final sitter = await repo.sitterProfile();
    if (mounted) setState(() { _user = user; _sitter = sitter; _loading = false; });
  }

  String _val(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  @override
  Widget build(BuildContext context) {
    final fullName = _val(_user?['full_name']?.toString());
    final email    = _val(_user?['email']?.toString());
    final phone    = _val(_user?['phone']?.toString());
    final bio      = _val(_sitter?['bio']?.toString());
    final dob      = _sitter?['date_of_birth']?.toString();
    String ageStr = '—';
    if (dob != null) {
      final d = DateTime.tryParse(dob);
      if (d != null) {
        final age = (){final n=DateTime.now();return (n.year-d.year)-((n.month<d.month||(n.month==d.month&&n.day<d.day))?1:0);}();
        ageStr = '$age years old';
      }
    }

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
                  color: Colors.transparent,
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
                      const Text('Personal Information',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('View your personal details',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
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
                                        builder: (_) => EditPersonalInformationScreen(
                                          initialFullName: _user?['full_name']?.toString() ?? '',
                                          initialEmail: _user?['email']?.toString() ?? '',
                                          initialPhone: _user?['phone']?.toString() ?? '',
                                          initialBio: _sitter?['bio']?.toString() ?? '',
                                          initialDob: dob ?? '',
                                        ),
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
                                        SvgPicture.asset('assets/edit-icon.svg',
                                            width: 18, height: 18,
                                            colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn)),
                                        const SizedBox(width: 8),
                                        const Text('Edit',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFA8D8EA))),
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
                                    InfoField(label: 'Full Name', value: fullName),
                                    InfoField(label: 'Email', value: email),
                                    InfoField(label: 'Phone', value: phone),
                                    InfoField(label: 'Age', value: ageStr),
                                    InfoField(label: 'Bio', value: bio, showDivider: false),
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
