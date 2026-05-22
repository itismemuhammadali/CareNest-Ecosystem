import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'personal_information_screen.dart';
import 'home_address_screen.dart';
import 'emergency_contact_screen.dart';
import 'children_information_screen.dart';
import 'home_safety_information_screen.dart';
import 'babysitter_preferences_screen.dart';
import 'notification_preferences_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? _avatarUrl;
  bool _avatarUploading = false;
  int _childrenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadChildrenCount();
  }

  Future<void> _loadAvatar() async {
    final row = await ProfileRepository(Supabase.instance.client).currentUserRow();
    if (!mounted) return;
    setState(() => _avatarUrl = row?['avatar_url'] as String?);
  }

  Future<void> _loadChildrenCount() async {
    final children = await ProfileRepository(Supabase.instance.client).listFamilyChildren();
    if (!mounted) return;
    setState(() => _childrenCount = children.length);
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() => _avatarUploading = true);
    try {
      final url = await ProfileRepository(Supabase.instance.client)
          .uploadAvatar(file.bytes!, file.name);
      if (mounted) setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
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

          // Scrollable content
          Column(
            children: [
              // Header with back button and title
              Header2(
                title: 'Edit Profile',
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Profile picture section
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _avatarUploading ? null : _pickAndUploadAvatar,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: _avatarUrl != null
                                          ? NetworkImage(_avatarUrl!) as ImageProvider
                                          : const AssetImage('assets/profilePicture.png'),
                                    ),
                                    if (_avatarUploading)
                                      const Positioned.fill(
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.black45,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFC8F0FF),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC8F0FF),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF0F172A), width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Manage your account details and preferences',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Verified Parent Account
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/tick-icon.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF10B981),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Verified Parent Account',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'ID Verified • Phone Verified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Personal Information
                        _buildMenuCard(
                          icon: 'assets/profile-icon.svg',
                          title: 'Personal Information',
                          subtitle: 'Name, email, phone, date of birth',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PersonalInformationScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Home Address
                        _buildMenuCard(
                          icon: 'assets/home-icon.svg',
                          title: 'Home Address',
                          subtitle: 'Street, city, state, zip code',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HomeAddressScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Emergency Contact
                        _buildMenuCard(
                          icon: 'assets/shield.svg',
                          title: 'Emergency Contact',
                          subtitle: 'Backup contact information',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmergencyContactScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Children Information
                        _buildMenuCard(
                          icon: 'assets/baby.svg',
                          title: 'Children Information',
                          subtitle: _childrenCount == 0
                              ? 'Ages, allergies, special needs'
                              : '$_childrenCount ${_childrenCount == 1 ? 'child' : 'children'} • Ages, allergies, special needs',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChildrenInformationScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Home & Safety Information
                        _buildMenuCard(
                          icon: 'assets/location.svg',
                          title: 'Home & Safety Information',
                          subtitle: 'Home type, pets, access codes, WiFi',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HomeSafetyInformationScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Babysitter Preferences
                        _buildMenuCard(
                          icon: 'assets/heart.svg',
                          title: 'Babysitter Preferences',
                          subtitle: 'Gender, age, language, certifications',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BabysitterPreferencesScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Notification Preferences
                        _buildMenuCard(
                          icon: 'assets/bell.svg',
                          title: 'Notification Preferences',
                          subtitle: 'Email, SMS, push alerts',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Privacy & Security info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/shield.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFA8D8EA),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Your Privacy & Security\nAll information is encrypted and stored securely. We never share your information with babysitters you hire. Home access codes are never shared until confirmation.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFFA8D8EA),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFA8D8EA),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
