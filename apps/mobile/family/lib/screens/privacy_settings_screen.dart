import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisibleToBabysitters = true;
  bool _showLocation = true;
  bool _showPhoneNumber = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _jobRecommendations = true;
  bool _shareDataWithPartners = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _profileVisibleToBabysitters = prefs.getBool('family_privacy_profile_visible') ?? true;
      _showLocation = prefs.getBool('family_privacy_show_location') ?? true;
      _showPhoneNumber = prefs.getBool('family_privacy_show_phone') ?? false;
      _emailNotifications = prefs.getBool('family_privacy_email_notif') ?? true;
      _smsNotifications = prefs.getBool('family_privacy_sms_notif') ?? false;
      _pushNotifications = prefs.getBool('family_privacy_push_notif') ?? true;
      _jobRecommendations = prefs.getBool('family_privacy_job_recs') ?? true;
      _shareDataWithPartners = prefs.getBool('family_privacy_share_data') ?? false;
    });
    try {
      final remote = await ProfileRepository(Supabase.instance.client).getFamilyPrivacySettings();
      if (!mounted || remote.isEmpty) return;
      setState(() {
        _profileVisibleToBabysitters = remote['profile_visible'] as bool? ?? _profileVisibleToBabysitters;
        _showLocation = remote['show_location'] as bool? ?? _showLocation;
        _showPhoneNumber = remote['show_phone'] as bool? ?? _showPhoneNumber;
        _emailNotifications = remote['email_notifications'] as bool? ?? _emailNotifications;
        _smsNotifications = remote['sms_notifications'] as bool? ?? _smsNotifications;
        _pushNotifications = remote['push_notifications'] as bool? ?? _pushNotifications;
        _jobRecommendations = remote['job_recommendations'] as bool? ?? _jobRecommendations;
        _shareDataWithPartners = remote['share_data'] as bool? ?? _shareDataWithPartners;
      });
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    await _prefs?.setBool('family_privacy_profile_visible', _profileVisibleToBabysitters);
    await _prefs?.setBool('family_privacy_show_location', _showLocation);
    await _prefs?.setBool('family_privacy_show_phone', _showPhoneNumber);
    await _prefs?.setBool('family_privacy_email_notif', _emailNotifications);
    await _prefs?.setBool('family_privacy_sms_notif', _smsNotifications);
    await _prefs?.setBool('family_privacy_push_notif', _pushNotifications);
    await _prefs?.setBool('family_privacy_job_recs', _jobRecommendations);
    await _prefs?.setBool('family_privacy_share_data', _shareDataWithPartners);
    try {
      await ProfileRepository(Supabase.instance.client).saveFamilyPrivacySettings({
        'profile_visible': _profileVisibleToBabysitters,
        'show_location': _showLocation,
        'show_phone': _showPhoneNumber,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'push_notifications': _pushNotifications,
        'job_recommendations': _jobRecommendations,
        'share_data': _shareDataWithPartners,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // Header
            Header2(
              title: 'Privacy Settings',
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
                child: Column(
                  children: [
                    // Shield icon
                    Image.asset(
                      'assets/shieldimg.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 10),

                    // Title and Subtitle
                    const Text(
                      'Privacy Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Control your data and who can see it',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Privacy Section Title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Profile Privacy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Profile Privacy Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x991E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleRow(
                            title: 'Profile Visible to Babysitters',
                            subtitle: 'Allow babysitters to see your profile when you post jobs',
                            value: _profileVisibleToBabysitters,
                            onChanged: (value) {
                              setState(() {
                                _profileVisibleToBabysitters = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            title: 'Show Location',
                            subtitle: 'Display your city to help babysitters find nearby jobs',
                            value: _showLocation,
                            onChanged: (value) {
                              setState(() {
                                _showLocation = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            title: 'Show Phone Number',
                            subtitle: 'Display phone number on your profile',
                            value: _showPhoneNumber,
                            onChanged: (value) {
                              setState(() {
                                _showPhoneNumber = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notifications Section Title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Notifications Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x991E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleRow(
                            title: 'Email Notifications',
                            subtitle: 'Receive updates about jobs and messages via email',
                            value: _emailNotifications,
                            onChanged: (value) {
                              setState(() {
                                _emailNotifications = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            title: 'SMS Notifications',
                            subtitle: 'Get text messages for important updates',
                            value: _smsNotifications,
                            onChanged: (value) {
                              setState(() {
                                _smsNotifications = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            title: 'Push Notifications',
                            subtitle: 'Receive push notifications on your device',
                            value: _pushNotifications,
                            onChanged: (value) {
                              setState(() {
                                _pushNotifications = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Data & Personalization Section Title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Data & Personalization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Data & Personalization Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x991E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleRow(
                            title: 'Job Recommendations',
                            subtitle: 'Get personalized babysitter recommendations',
                            value: _jobRecommendations,
                            onChanged: (value) {
                              setState(() {
                                _jobRecommendations = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            title: 'Share Data with Partners',
                            subtitle: 'Allow sharing anonymized data with trusted partners',
                            value: _shareDataWithPartners,
                            onChanged: (value) {
                              setState(() {
                                _shareDataWithPartners = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _savePreferences();
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC8F0FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Privacy Info Container (bottom)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Color(0xFFA8D8EA),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Your privacy is important to us. We never sell your personal information.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Image.asset(
            value ? 'assets/switchon.png' : 'assets/switchoff.png',
            width: 40,
            height: 24,
          ),
        ),
      ],
    );
  }
}
