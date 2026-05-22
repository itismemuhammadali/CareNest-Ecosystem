import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisibility = true;
  bool _showLocation = true;
  bool _showAge = true;
  bool _allowMessages = true;
  bool _shareActivity = false;
  bool _analytics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
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
                // ── Pinned transparent header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Privacy Settings',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control your privacy preferences',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Info notice
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AD4B5FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0x4DD4B5FF), width: 1.09),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                    'assets/sheild-icon.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFD4B5FF),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Your privacy is important. We never share your personal information without your consent.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFD4B5FF),
                                          height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Guardian information is always protected and only shared with verified families.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFD4B5FF)
                                        .withValues(alpha: 0.7),
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Profile Privacy ──
                        _sectionLabel('Profile Privacy'),
                        const SizedBox(height: 10),
                        _toggleCard(
                          svgAsset: 'assets/profile-icon.svg',
                          title: 'Profile Visibility',
                          subtitle: 'Allow families to view your profile',
                          value: _profileVisibility,
                          onChanged: (v) =>
                              setState(() => _profileVisibility = v),
                        ),
                        const SizedBox(height: 10),
                        _toggleCard(
                          icon: Icons.location_on_outlined,
                          title: 'Show Location',
                          subtitle: 'Display your city to potential employers',
                          value: _showLocation,
                          onChanged: (v) =>
                              setState(() => _showLocation = v),
                        ),
                        const SizedBox(height: 10),
                        _toggleCard(
                          svgAsset: 'assets/sheild-icon.svg',
                          title: 'Show Age',
                          subtitle: 'Display your age on your profile',
                          value: _showAge,
                          onChanged: (v) => setState(() => _showAge = v),
                        ),
                        const SizedBox(height: 24),

                        // ── Communication ──
                        _sectionLabel('Communication'),
                        const SizedBox(height: 10),
                        _toggleCard(
                          svgAsset: 'assets/message-icon.svg',
                          title: 'Allow Messages',
                          subtitle: 'Let families send you messages',
                          value: _allowMessages,
                          onChanged: (v) =>
                              setState(() => _allowMessages = v),
                        ),
                        const SizedBox(height: 24),

                        // ── Data & Privacy ──
                        _sectionLabel('Data & Privacy'),
                        const SizedBox(height: 10),
                        _toggleCard(
                          svgAsset: 'assets/sheild-icon.svg',
                          title: 'Share Activity',
                          subtitle:
                              'Share your activity for better job matches',
                          value: _shareActivity,
                          onChanged: (v) =>
                              setState(() => _shareActivity = v),
                        ),
                        const SizedBox(height: 10),
                        _toggleCard(
                          svgAsset: 'assets/sheild-icon.svg',
                          title: 'Analytics',
                          subtitle: 'Help improve the app with usage data',
                          value: _analytics,
                          onChanged: (v) => setState(() => _analytics = v),
                        ),
                        const SizedBox(height: 24),

                        // ── Data Protection card ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Protection',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All your personal information is encrypted and stored securely. We comply with all relevant privacy regulations and never sell your data.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                    height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text(
                                    'Read our Privacy Policy',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFA8D8EA),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward,
                                      color: Color(0xFFA8D8EA), size: 14),
                                ],
                              ),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)),
    );
  }

  Widget _toggleCard({
    String? svgAsset,
    IconData? icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFA8D8EA),
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(icon, color: const Color(0xFFA8D8EA), size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),

          // Toggle
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFA8D8EA),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
