import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile/profile_header_card.dart';
import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_about_card.dart';
import '../utils/custom_page_route.dart';
import 'personal_information_screen.dart';
import 'guardian_details_screen.dart';
import 'wallet_screen.dart';
import 'certifications_screen.dart';
import 'sign_in_screen.dart';
import 'settings_screen.dart';
import 'documents_screen.dart';
import 'emergency_contact_screen.dart';

class ProfileTab extends StatefulWidget {
  final ValueChanged<int> onNavTap;
  const ProfileTab({super.key, required this.onNavTap});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _name = '';
  String _email = '';
  String? _avatarUrl;
  bool _isAdminVerified = false;
  bool _guardianConsentGiven = false;
  bool _loadingProfile = false;

  static const List<Map<String, dynamic>> _menuItems = [
    {'svgAsset': 'assets/profile-icon.svg', 'label': 'Personal Information'},
    {'icon': Icons.people_outline, 'label': 'Guardian Details'},
    {'icon': Icons.emergency_outlined, 'label': 'Emergency Contact'},
    {'svgAsset': 'assets/wallet-icon.svg', 'label': 'Wallet & Earnings'},
    {'svgAsset': 'assets/certificate-icon.svg', 'label': 'Certifications'},
    {'svgAsset': 'assets/document-icon.svg', 'label': 'Documents'},
    {'svgAsset': 'assets/setting-icon.svg', 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // S13: Guard against concurrent _load() calls (race condition on rapid navigation)
    if (_loadingProfile) return;
    _loadingProfile = true;
    try {
      final repo = ProfileRepository(Supabase.instance.client);
      final u = await repo.currentUserRow();
      Map<String, dynamic>? sp;
      try {
        sp = await repo.sitterProfile();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _email = u?['email']?.toString() ?? '';
        final fn = u?['full_name']?.toString().trim() ?? '';
        _name = fn.isNotEmpty ? fn : _email;
        _avatarUrl = u?['avatar_url']?.toString();
        _isAdminVerified = sp?['is_active'] == true;
        _guardianConsentGiven = sp?['guardian_consent_status']?.toString() == 'approved';
      });
    } finally {
      _loadingProfile = false;
    }
  }

  void _showSignOutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign Out',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(fontSize: 14, color: Color(0x99A8D8EA)),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  CustomPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              },
              child: Container(
                width: double.infinity,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Yes, Sign Out',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account & verification',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ProfileHeaderCard(
                  displayName: _name,
                  displayEmail: _email,
                  avatarUrl: _avatarUrl,
                  isAdminVerified: _isAdminVerified,
                  guardianConsentGiven: _guardianConsentGiven,
                ),
                const SizedBox(height: 12),
                ..._menuItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProfileMenuItem(
                        icon: item['icon'] as IconData?,
                        svgAsset: item['svgAsset'] as String?,
                        label: item['label'] as String,
                        onTap: (item['label'] == 'Personal Information')
                            ? () => Navigator.push(
                                  context,
                                  CustomPageRoute(
                                    builder: (_) =>
                                        const PersonalInformationScreen(),
                                  ),
                                )
                            : (item['label'] == 'Guardian Details')
                                ? () => Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        builder: (_) =>
                                            const GuardianDetailsScreen(),
                                      ),
                                    )
                                : (item['label'] == 'Emergency Contact')
                                ? () => Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        builder: (_) =>
                                            const EmergencyContactScreen(),
                                      ),
                                    )
                                : (item['label'] == 'Wallet & Earnings')
                                    ? () => Navigator.push(
                                          context,
                                          CustomPageRoute(
                                            builder: (_) =>
                                                const WalletScreen(),
                                          ),
                                        )
                                    : (item['label'] == 'Settings')
                                ? () => Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        builder: (_) =>
                                            const SettingsScreen(),
                                      ),
                                    )
                                : (item['label'] == 'Documents')
                                    ? () => Navigator.push(
                                          context,
                                          CustomPageRoute(
                                            builder: (_) =>
                                                const DocumentsScreen(),
                                          ),
                                        )
                                    : (item['label'] == 'Certifications')
                                        ? () => Navigator.push(
                                              context,
                                              CustomPageRoute(
                                                builder: (_) =>
                                                    const CertificationsScreen(),
                                              ),
                                            )
                                        : null,
                      ),
                    )),
                const SizedBox(height: 8),
                const Text(
                  'About Me',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                const ProfileAboutCard(),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x991E293B),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0x1AA8D8EA), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'App Version',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1.0.0',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showSignOutSheet(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x33FB2C36),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0x4DFB2C36), width: 1.09),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout,
                            color: Color(0xFFFF6467), size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6467)),
                        ),
                      ],
                    ),
                  ),
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
