import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/profile/profile_header_card.dart';
import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_about_card.dart';
import '../utils/custom_page_route.dart';
import 'personal_information_screen.dart';
import 'certifications_screen.dart';
import 'sign_in_screen.dart';
import 'settings_screen.dart';
import 'documents_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 3;
  String? _displayName;
  String? _displayEmail;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final u = await ProfileRepository(client).currentUserRow();
    if (!mounted) return;
    setState(() {
      _displayName = (u?['full_name'] as String?)?.trim().isNotEmpty == true
          ? u!['full_name'] as String
          : (u?['email'] as String? ?? '');
      _displayEmail = u?['email'] as String?;
      _avatarUrl = u?['avatar_url'] as String?;
    });
  }

  void _showSignOutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Padding(
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
                color: Colors.white,
              ),
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
                // Close modal using modal context
                Navigator.pop(modalContext);
                
                // Sign out
                await Supabase.instance.client.auth.signOut();
                
                // Navigate using parent context
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
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(modalContext),
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
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _menuItems = [
    {'svgAsset': 'assets/profile-icon.svg',     'label': 'Personal Information'},
    {'icon': Icons.people_outline,               'label': 'Guardian Details'},
    {'svgAsset': 'assets/wallet-icon.svg',      'label': 'Wallet & Earnings'},
    {'svgAsset': 'assets/certificate-icon.svg', 'label': 'Certifications'},
    {'svgAsset': 'assets/document-icon.svg',    'label': 'Documents'},
    {'svgAsset': 'assets/setting-icon.svg',     'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          // Gradient overlay
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
                // Header panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your account & verification',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Profile card
                        ProfileHeaderCard(displayName: _displayName, displayEmail: _displayEmail, avatarUrl: _avatarUrl),
                        const SizedBox(height: 12),

                        // Menu items
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

                        // About Me section
                        const Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const ProfileAboutCard(),
                        const SizedBox(height: 12),

                        // App version card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'App Version',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '1.0.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sign Out button
                        GestureDetector(
                          onTap: () => _showSignOutSheet(context),
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0x33FB2C36),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x4DFB2C36),
                                width: 1.09,
                              ),
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
                                    color: Color(0xFFFF6467),
                                  ),
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

                BottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _currentNavIndex = index);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
