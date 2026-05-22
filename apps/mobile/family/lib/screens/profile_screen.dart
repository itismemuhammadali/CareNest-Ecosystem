import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/bottom_nav_bar.dart';
import 'package:star_sitter_family/widgets/confirmation_dialog.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'background_check_submit_screen.dart';
import 'manage_billing_screen.dart';
import 'my_posted_jobs_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _selectedIndex = 3;
  String _displayName = '';
  String? _avatarUrl;
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final repo = ProfileRepository(client);
    final u = await repo.currentUserRow();
    if (!mounted) return;
    setState(() {
      _displayName = (u?['full_name'] as String?)?.trim().isNotEmpty == true
          ? u!['full_name'] as String
          : (u?['email'] as String? ?? '');
      _avatarUrl = u?['avatar_url'] as String?;
    });
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(right: 24, bottom: 20, left: 24, top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 20),
                    const Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Profile info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _avatarUploading ? null : _pickAndUploadAvatar,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                              ? NetworkImage(_avatarUrl!) as ImageProvider
                                              : const AssetImage('assets/profilePicture.png'),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFA8D8EA),
                                              shape: BoxShape.circle,
                                            ),
                                            child: _avatarUploading
                                                ? const Padding(
                                                    padding: EdgeInsets.all(3),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  )
                                                : const Icon(Icons.edit, size: 11, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _displayName.isEmpty ? 'Family account' : _displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF166534).withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            '✓ Verified Account',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4ADE80),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA8D8EA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Membership Status',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const Text(
                                          'Standard',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Next Renewal',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const Text(
                                          'See Billing',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildMenuCardRaw(
                          icon: 'assets/myp.svg',
                          title: 'My Posted Jobs',
                          subtitle: 'View all jobs & applicants',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyPostedJobsScreen()),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Account Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuCardRaw(
                          icon: 'assets/editp.svg',
                          title: 'Edit Personal Information',
                          subtitle: 'Update your profile details',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuCardRaw(
                          icon: 'assets/manageb.svg',
                          title: 'Manage Billing',
                          subtitle: 'View subscription & invoices',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ManageBillingScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuCardRaw(
                          icon: 'assets/lockp.svg',
                          title: 'Change Password',
                          subtitle: 'Update your password',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuCardRaw(
                          icon: 'assets/shieldp.svg',
                          title: 'Privacy Settings',
                          subtitle: 'Control your data & notifications',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuCardRaw(
                          icon: 'assets/shieldp.svg',
                          title: 'Submit background check',
                          subtitle: 'Upload documents to Supabase Storage + pending review',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BackgroundCheckSubmitScreen(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        StreamBuilder<Map<String, dynamic>?>(
                          stream: ProfileRepository(Supabase.instance.client).watchFamilyProfileRow(),
                          builder: (context, snap) {
                            final status = snap.data?['bg_check_status']?.toString() ?? 'not_submitted';
                            final approved = status == 'approved';
                            final pending = status == 'pending';
                            final badgeLabel = approved ? 'Approved' : pending ? 'Pending review' : 'Not submitted';
                            final badgeColor = approved ? const Color(0xFF4ADE80) : pending ? const Color(0xFFFFA500) : Colors.white38;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x991E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset('assets/noteppp.png', width: 20, height: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Background Check', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                            const SizedBox(height: 2),
                                            Text(badgeLabel, style: TextStyle(fontSize: 12, color: badgeColor)),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        approved ? Icons.check : pending ? Icons.hourglass_top : Icons.close,
                                        color: badgeColor, size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      SvgPicture.asset('assets/imagep.svg', width: 20, height: 20),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Identity Verified', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                            SizedBox(height: 2),
                                            Text('Via Supabase Auth', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.check, color: Color(0xFF4ADE80), size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _showLogOutDialog(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _showDeleteAccountDialog(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
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

      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                if (index == 3) return; // Already on Profile
                // Pop back to HomeScreen root — it manages the shared IndexedStack
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
    );
  }

  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Log Out?',
          description: 'Are you sure you want to log out? You will be redirected to the sign-in page.',
          confirmButtonText: 'Yes, Log Out',
          cancelButtonText: 'Stay Logged In',
          confirmButtonColor: const Color(0xFFEF4444),
          confirmButtonBorderColor: const Color(0xFFEF4444),
          iconBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
          iconPath: 'assets/yellowHazard.svg',
          iconColor: const Color(0xFFEF4444),
          onConfirm: () async {
            Navigator.of(context).pop();
            await Supabase.instance.client.auth.signOut();
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Delete Account?',
          description: 'This action cannot be undone. All your data, job history, and subscription information will be permanently deleted.',
          confirmButtonText: 'Yes, Delete Account',
          cancelButtonText: 'Keep Account',
          confirmButtonColor: const Color(0xFFEF4444),
          confirmButtonBorderColor: const Color(0xFFEF4444),
          iconBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
          iconPath: 'assets/yellowHazard.svg',
          iconColor: const Color(0xFFEF4444),
          onConfirm: () async {
            Navigator.of(context).pop();
            try {
              await Supabase.instance.client.rpc('delete_own_account');
            } catch (_) {}
            await Supabase.instance.client.auth.signOut();
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Widget _buildMenuCardRaw({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2D3E),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 18,
                  height: 18,
                  placeholderBuilder: (context) => const SizedBox(width: 18, height: 18),
                ),
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
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}