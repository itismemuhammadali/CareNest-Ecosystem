import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/settings/settings_item.dart';
import '../widgets/settings/settings_section.dart';
import '../utils/custom_page_route.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = true;
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
      _pushNotifications = prefs.getBool('sitter_pushNotifs') ?? true;
      _darkMode = prefs.getBool('sitter_darkMode') ?? true;
    });
    try {
      final remote = await ProfileRepository(Supabase.instance.client).getSitterPreferences();
      if (!mounted) return;
      setState(() {
        _pushNotifications = remote['push_notifications'] as bool? ?? _pushNotifications;
        _darkMode = remote['dark_mode'] as bool? ?? _darkMode;
      });
    } catch (_) {}
  }

  Future<void> _syncToCloud() async {
    try {
      await ProfileRepository(Supabase.instance.client).saveSitterPreferences({
        'push_notifications': _pushNotifications,
        'dark_mode': _darkMode,
      });
    } catch (_) {}
  }

  void _setPushNotifications(bool v) {
    setState(() => _pushNotifications = v);
    _prefs?.setBool('sitter_pushNotifs', v);
    _syncToCloud();
  }

  void _setDarkMode(bool v) {
    setState(() => _darkMode = v);
    _prefs?.setBool('sitter_darkMode', v);
    _syncToCloud();
  }

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
                // ── Pinned header ──
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
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Settings',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your preferences and account',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
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
                        const SizedBox(height: 24),

                  // Preferences section
                  SettingsSection(
                    title: 'Preferences',
                    items: [
                      SettingsItem(
                        svgAsset: 'assets/bell-icon.svg',
                        title: 'Push Notifications',
                        subtitle: 'Receive updates about jobs and messages',
                        trailing: Switch(
                          value: _pushNotifications,
                          onChanged: _setPushNotifications,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFFA8D8EA),
                          inactiveThumbColor: Colors.white38,
                          inactiveTrackColor: Colors.white12,
                        ),
                      ),
                      SettingsItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        trailing: Switch(
                          value: _darkMode,
                          onChanged: _setDarkMode,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFFA8D8EA),
                          inactiveThumbColor: Colors.white38,
                          inactiveTrackColor: Colors.white12,
                        ),
                      ),
                      SettingsItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English (app language is fixed in this version)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Security & Privacy section
                  SettingsSection(
                    title: 'Security & Privacy',
                    items: [
                      SettingsItem(
                        svgAsset: 'assets/lock-icon.svg',
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () => Navigator.push(
                          context,
                          CustomPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                      ),
                      SettingsItem(
                        svgAsset: 'assets/sheild-icon.svg',
                        title: 'Privacy Settings',
                        subtitle: 'Manage your privacy preferences',
                        onTap: () => Navigator.push(
                          context,
                          CustomPageRoute(
                            builder: (_) => const PrivacySettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Support section
                  SettingsSection(
                    title: 'Support',
                    items: [
                      SettingsItem(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        subtitle: 'Get help and support',
                        onTap: () => Navigator.push(
                          context,
                          CustomPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
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
